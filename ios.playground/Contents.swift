import Foundation
import UIKit

struct Game {
    let dice = [
                ["A", "Z", "F", "S", "Qu", "B"],
                ["G", "C", "S", "V", "P", "A"],
                ["H", "I", "S", "E", "R", "N"],
                ["A", "I", "O", "B", "M", "C"],
                ["T", "I", "V", "E", "N", "G"],
                ["M", "O", "V", "D", "I", "T"],
                ["V", "N", "D", "Z", "A", "E"],
                ["O", "A", "A", "I", "E", "T"],
                ["F", "R", "I", "P", "A", "G"],
                ["M", "L", "R", "C", "O", "I"],
                ["O", "N", "F", "E", "B", "L"],
                ["L", "O", "C", "I", "D", "M"],
                ["T", "B", "R", "L", "I", "A"],
                ["C", "F", "A", "R", "O", "I"],
                ["N", "U", "E", "O", "C", "T"],
                ["L", "E", "P", "U", "S", "T"],
                ["N", "O", "D", "E", "S", "T"],
                ["A", "I", "O", "S", "M", "R"],
                ["T", "G", "C", "A", "P", "I"],
                ["L", "A", "R", "E", "S", "C"],
                ["A", "B", "O", "O", "Qu", "M"],
                ["G", "U", "E", "O", "N", "L"],
                ["C", "D", "P", "M", "A", "E"],
                ["R", "O", "E", "L", "U", "I"],
                ["H", "I", "F", "E", "I", "E"],
               ]
    
    let language = "it_IT"
    let pathStart = -1
    let numberOfDices = 25
    let numberOfColumns = 5
    let numberOfFaces = 6

    let checker = UITextChecker()
    
    var board: [[String]]
    
    init(board: [[String]]? = nil) {
        if let board = board {
            self.board = board
        }
        else {
            var board = [[String]](repeating: [String](repeating: "", count: numberOfColumns), count: numberOfColumns)
            
            for i in 0..<numberOfDices {
                let row = i / numberOfColumns
                let col = i - (row * numberOfColumns)
                board[row][col] = dice[i][Int.random(in: 0..<numberOfFaces)]
            }
            
            self.board = board
        }
    }
    
    func printBoard() {
        for row in 0..<numberOfColumns {
            print(String(repeating: "+---", count: numberOfColumns) + "+")
            var column = ""
            for col in 0..<numberOfColumns {
                let face = board[row][col]
                column += "| \(face)"
                column += face.count > 1 ? "" : " "
            }
            print(column + "|")
        }
        print(String(repeating: "+---", count: numberOfColumns) + "+")
    }
    
    func inRange(pos: Int, last: Int) -> Bool {
        for i in -1...1 {
            let currentPos = pos + (i * numberOfColumns)
            let currentRow = currentPos / numberOfColumns
            let currentCol = currentPos - (currentRow * numberOfColumns)

            if currentRow >= 0 && currentRow < numberOfColumns && currentCol >= 0 && currentCol < numberOfColumns {
                let leftColumnPos = (currentRow * numberOfColumns) + max(0, currentCol-1)
                let rightColumnPos = (currentRow * numberOfColumns) + min(numberOfColumns-1, currentCol+1)

                let range = leftColumnPos...rightColumnPos
                if range.contains(last) {
//                     print(pos, last, true)
                    return true
                }
            }
        }
        
//        print(pos, last, false)
        return false
    }
    
    func canAdd(pos: Int, to path: [Int]) -> Bool {
        if !path.contains(pos) {
            let last = path.last!
            if last == pathStart || inRange(pos: pos, last: last) {
                return true
            }
        }
        
        return false
    }
    
    func getWord(from path: [Int]) -> String? {
        guard path.count > 0 else { return nil }
        
        return path[1...].map{ i in
            let row = i / numberOfColumns
            let col = i - (row * numberOfColumns)
            return board[row][col]
        }.joined(separator: "").lowercased()
    }
    
    func isReal(word: String, fullCheck: Bool = true) -> Bool {
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: language)
        
        if misspelledRange.location == NSNotFound {
            if !fullCheck {
                return true
            }
            if word.count > 2 {
                let subWord = String(word[...word.index(word.endIndex, offsetBy: -2)])
                for next in (completionWords(partial: subWord).filter{ $0.count == word.count }) {
                    if next == word {
                        return true
                    }
                }
            }
        }
        
        return false
    }

    func completionWords(partial: String) -> [String] {
        let completions = checker.completions(
                        forPartialWordRange: NSRange(0..<partial.utf16.count),
                        in: partial,
                        language: language
                      )
        return completions ?? []
    }

    func findAllWords() -> [String] {
        var words = Set<String>()
        var paths = [[pathStart]]
        
        while true {
            var newPaths = [[Int]]()
            //for i in 0..<numberOfDices {
            DispatchQueue.concurrentPerform(iterations: numberOfDices) { i in
                for path in paths {
                    if canAdd(pos: i, to: path) {
                        var newPath = path
                        newPath.append(i)
                        
                        if let word = getWord(from: newPath) {
                            if word.count > 2 && isReal(word: word) {
                                words.insert(word)
                            }
                            
                            if !completionWords(partial: word).isEmpty {
                                newPaths.append(newPath)
                            }
                        }
                    }
                }
            }
            if newPaths.isEmpty {
                break
            }
            paths = newPaths
        }
        
        return Array(words)
    }
    
    func getPositions(letter: String) -> [Int] {
        board.flatMap{ $0 }.enumerated().filter{ i, v in v == letter }.map{ i, v in i }
    }
    
    func findPaths(word: String) -> [[Int]] {
        var paths = [[pathStart]]
        
        for letter in word.uppercased() {
            var newPaths = [[Int]]()
            for pos in getPositions(letter: String(letter)) {
                for path in paths {
                    if canAdd(pos: pos, to: path) {
                        var newPath = path
                        newPath.append(pos)
                        newPaths.append(newPath)
                    }
                }
            }
            paths = newPaths
        }
        
        return paths.map{ Array($0[1...]) }
    }
}

//var game = Game()
var game = Game(board: [["B", "C", "I", "I", "T"], ["V", "A", "A", "I", "O"], ["N", "O", "T", "F", "N"], ["P", "N", "R", "A", "C"], ["A", "U", "E", "E", "F"]])
game.printBoard()
print(game.findAllWords().sorted(by: {$0.count > $1.count}))
print(game.findPaths(word: "notaio"))
