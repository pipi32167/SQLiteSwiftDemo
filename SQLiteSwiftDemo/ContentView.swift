//
//  ContentView.swift
//  SQLiteSwiftDemo
//
//  Created by Trillion Young on 2023/6/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var resultText: String = ""
    @State private var jiebaSegmentation: Bool = false
    @State private var highlight: Bool = false

    var body: some View {
        VStack {
            TextField("输入查询内容", text: $inputText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button(action: {
                    self.add()
                }) {
                    Text("添加")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(action: {
                    self.search()
                }) {
                    Text("查询")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            HStack {
                Toggle(isOn: $jiebaSegmentation) {
                    Text("结巴分词")
                }
                .padding()

                Toggle(isOn: $highlight) {
                    Text("高亮显示")
                }
                .padding()
            }

            TextEditor(text: $resultText)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
        }
        .padding()
        .onAppear {
            do {
                resultText = try DB.shared.queryAll().joined(separator: "\n")
            } catch {
                print("queryAll error: \(error.localizedDescription)")
            }
            
        }
    }
    
    func add() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            return
        }
        do {
            try DB.shared.insertOne(text: input)
            resultText = try DB.shared.queryAll().joined(separator: "\n")
        } catch {
            print("insertOne error: \(error.localizedDescription)")
        }
    }
    
    func search() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            return
        }

        do {
            resultText = try DB.shared.query(
                text: input,
                usingJieba: self.jiebaSegmentation,
                usingHighlight: self.highlight
            ).joined(separator: "\n")
        } catch {
            print("query error: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
