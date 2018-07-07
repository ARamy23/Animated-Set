//
//  Card.swift
//  Set (By Code)
//
//  Created by Ahmed Ramy on 6/4/18.
//  Copyright © 2018 Ahmed Ramy. All rights reserved.
//

import Foundation

enum Shape
{
    case diamond
    case oval
    case squiggle
    
    static let allValues = [diamond, oval, squiggle]
}

enum Color
{
    case green
    case purple
    case red
    
    static let allValues = [green, purple, red]

}

enum Number
{
    case one
    case two
    case three
    
    static let allValues = [one, two, three]

}

enum Shading
{
    case outlined
    case stripped
    case solid
    
    static let allValues = [outlined, stripped, solid]
}

struct Card
{
    let shape: Shape
    let color: Color
    let number: Number
    let shading: Shading
}


