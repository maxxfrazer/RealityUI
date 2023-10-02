//
//  ContentView.swift
//  RealityUI+Example
//
//  Created by Max Cobb on 10/04/2023.
//

import SwiftUI

/// An enum object that will determine which 3D model to display
public enum RealityObject: String, CaseIterable {
    case toggle
    case slider
    case stepper
    case button
    case rotation
    case text
}

struct ContentView: View {
    /// 3D RealityUI object that is displayed
    @State var displayObject: RealityObject = .toggle
    @State var stepperTally = 0
    var body: some View {
        VStack {
            ARViewContainer(
                objectType: $displayObject, stepperTally: $stepperTally
            ).overlay {
                if self.displayObject == .stepper {
                    VStack {
                        Text("Stepper Count: \(stepperTally)")
                        Spacer()
                    }
                }
            }
            Picker("RealityUI Object", selection: $displayObject) {
                ForEach(RealityObject.allCases, id: \.self) { val in
                    Text(val.rawValue).tag(val)
                }
            }.pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
