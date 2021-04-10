//
//  ContentView.swift
//  ThrottlerExample
//
//  Created by Seoksoon Jang on 2021/04/10.
//

import SwiftUI
import Throttler

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Throttler used.")
            
            Button(action: {
                print("button clicked > Throttler used")
                Throttler.go {
                    take()
                }
            }) {
                Text(
                """
                PLEASE HIT ME AS FAST AS YOU CAN
                """)
            }
            .padding()
            
            Spacer()
            
            Text("Throttler NOT used.")
            
            Button(action: {
                print("button clicked > Throttler NOT used")
                take()
            }) {
                Text("PLEASE HIT ME AS FAST AS YOU CAN")
            }
            .padding()
            
            Spacer()
        }

    }
}

extension ContentView {
    func generateRandomString(upto: Int = 1,
                              initNumber: Int = 1,
                              isDuplicateAllowed: Bool = false,
                              output: [String] = []) -> [String] {
        // TODO: TCO or Trampoline to avoid call stack overflow
        var initNumber = initNumber
        
        if output.isEmpty {
            initNumber = upto
        }
        
        if isDuplicateAllowed ? (upto <= 0) : (initNumber <= Set(output).count) {
            return isDuplicateAllowed ? output : Array(Set(output))
        } else {
            let randomString = String((0...Int.random(in: (0...10))).map { _ in
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()!
            })
            
            return generateRandomString(
                upto: upto-1,
                initNumber: initNumber,
                isDuplicateAllowed: isDuplicateAllowed,
                output: output + [randomString])
        }
    }

    func take() {
        let res = generateRandomString(upto: 3000)
        print(res)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
