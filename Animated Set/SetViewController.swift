//
//  SetViewController.swift
//  Set (By Code)
//
//  Created by Ahmed Ramy on 6/7/18.
//  Copyright © 2018 Ahmed Ramy. All rights reserved.
//

import UIKit

class SetViewController: UIViewController {
    
    
    @IBOutlet weak var scoreLbl: UILabel!
    @IBOutlet weak var boardView: UIView!
    
    private let gameEngine = SetBrain()
    private var cardViews: [SetCardView]!
    
    private var selectedCards: [Card]
    {
        var result = [Card]()
        
        for card in gameEngine.boardCards.compactMap({$0})
        {
            if card.selected
            {
                result.append(card.card)
            }
        }
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startNewGame()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }
    
    @IBAction func didTapDeal(_ sender: Any)
    {
        cleanupView()
        gameEngine.drawThreeCardsToBoard()
        updateUI()
    }
    
    @IBAction func didTapNewGame(_ sender: Any)
    {
        startNewGame()
    }
    
    @IBAction func didTapHint(_ sender: Any)
    {
        let validCards = findValidCards()
        
        highlightValidCardsView(from: validCards)
        updateBoardView()
    }
    
    private func findValidCards() -> [Card]?
    {
        return gameEngine.findValidSet()
    }
    
    private func highlightValidCardsView(from cards: [Card]?)
    {
        if let validCardViews = cards?.compactMap({getCardView(for: $0)})
        {
            for cardView in cardViews
            {
                for validCardView in validCardViews
                {
                    if cardView == validCardView
                    {
                        cardView.isHinted = true
                        cardView.cardState = .hinted
                    }
                }
            }
        }
        
        cardViews.forEach{print($0.cardState)}
        cardViews.forEach({print($0.isHinted)})
    }
    
    
    private func startNewGame()
    {
        boardView.subviews.forEach { $0.removeFromSuperview() }
        cardViews = []
        gameEngine.reinitGame()
        updateUI()
    }
    
    private func updateUI()
    {
        updateScoreLabel()
        
        updateCardViews()
        
        updateBoardView()
        
    }
    
    private func updateScoreLabel()
    {
        scoreLbl.text = "Score: \(gameEngine.score)"
    }
    
    private func updateCardViews()
    {
        let boardCards = gameEngine.boardCards
        cardViews.removeAll()
        boardView.subviews.forEach {$0.removeFromSuperview()}
        for i in boardCards.indices
        {
            cardViews.append(getCardView(for: (boardCards[i]?.card)!))
        }
    }
    
    private func updateBoardView()
    {
        guard let grid = gridForCurrentBoard() else {return}
        
        
        for i in cardViews.indices
        {
            if let cardFrame = grid[i]
            {
                let cardView = cardViews[i]
                let margin = min(cardFrame.width, cardFrame.height) * 0.05
                cardView.frame = cardFrame.insetBy(dx: margin, dy: margin)
                
                if !boardView.subviews.contains(cardView)
                {
                    boardView.addSubview(cardView)
                }
            }
        }
        
    }
    
    private func gridForCurrentBoard() -> Grid?
    {
        let (rows, columns) = getRowsAndColumns(numberOfCards: gameEngine.boardCardsCount)
        
        guard rows > 0, columns > 0 else
        {
            return nil
        }
        
        return Grid(layout: .dimensions(rowCount: rows, columnCount: columns), frame: boardView.bounds)
    }
    
    ///
    /// Get the number of rows and columns that will correctly fit the given numberOfCards.
    ///
    private func getRowsAndColumns(numberOfCards: Int) -> (rows: Int, columns: Int) {
        
        // For 0 cards, we don't need any rows/columns
        if numberOfCards <= 0 {
            return (0, 0)
        }
        
        // TODO: The following logic is a "get it to work in 5 min." approach, so you may
        // want to review/change it.
        
        var rows = Int(sqrt(Double(numberOfCards)))
        
        if (rows*rows) < numberOfCards {
            rows += 1
        }
        
        var columns = rows
        
        if ( rows * (columns-1) ) >= numberOfCards {
            columns -= 1
        }
        
        return (rows, columns)
    }
    
    private func getCardView(for card: Card) -> SetCardView {
        
        // The view to populate/return
        let cardView = SetCardView(frame: CGRect())
        
        switch card.color {
        case .red: cardView.color = .red
        case .purple: cardView.color = .purple
        case .green: cardView.color = .green
        }
        
        switch card.shading {
        case .solid: cardView.shading = .solid
        case .stripped: cardView.shading = .stripped
        case .outlined: cardView.shading = .outlined
        }
        
        switch card.shape {
        case .oval: cardView.shape = .oval
        case .diamond: cardView.shape = .diamond
        case .squiggle: cardView.shape = .squiggle
        }
        
        switch card.number {
        case .one: cardView.number = .one
        case .two: cardView.number = .two
        case .three: cardView.number = .three
        }
        
        // Add tap-to select gestureRecognizer
        addGestureRecognizers(cardView)
        
        
        return cardView
    }
    
    private func addGestureRecognizers(_ cardView: SetCardView)
    {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapCard(recognizer:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        cardView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc private func tapCard(recognizer: UITapGestureRecognizer) {
        
        // Make sure the gesture was successful
        guard recognizer.state == .ended else {
            print("Tap gesture cancelled/failed")
            return
        }
        
        // We want to select/deselect the cardView where the gesture is coming from
        guard let cardView = recognizer.view as? SetCardView else {
            print("tapCard called from something not a CardView")
            return
        }
        
        // Toggle card selection
        cardView.isSelected = !cardView.isSelected
        gameEngine.selectCard(at: cardViews.index(of: cardView)!)
        
        print("current selected state of this card:-")
        print(cardView.cardState)
        // Process the board
        processBoard()
    }
    
    private func processBoard() {
        
        // Cleanup the board (i.e. remove any matched cards or de-highlight unmatched ones)
        cleanupView()
        
        // If there are three selected cards on the board, see if they match or not
        if selectedCards.count == 3 {
            
            // Check if selected cards are a set
            let isSet = gameEngine.isSetValid(cards: selectedCards)
            
            if isSet {
                match(selectedCards)
            }
            else {
                mismatch(selectedCards)
            }
            gameEngine.unselectAllCards()
            updateUI()
        }
    }
    
    private func cleanupView()
    {
        for index in cardViews.indices
        {
            // if card is not in the model
            if gameEngine.boardCards[index] == nil
            {
                cardViews[index].removeFromSuperview()
                updateUI()
            }
            
            cardViews[index].cardState = .regular
        }
    }
    
    ///
    /// Process the given cards as "matched". This means:
    ///    - Deselect card
    ///    - Set it into a "matched" state (i.e. green/success highlight color).
    ///
    private func match(_ cards: [Card]) {
        for card in cards
        {
            for cardView in cardViews
            {
                if cardView == getCardView(for: card)
                {
                    cardView.isSelected = false
                    cardView.cardState = .matched
                }
            }
        }
    }
    
    ///
    /// Process the given cards as "mismatched". This means:
    ///    - Deselect card
    ///    - Set it into a "mismatched" state (i.e. red/failure highlight color).
    ///
    private func mismatch(_ cards: [Card]) {
        for card in cards
        {
            for cardView in cardViews
            {
                if cardView == getCardView(for: card)
                {
                    cardView.isSelected = false
                    cardView.cardState = .mismatched
                }
            }
        }
    }
}


// Small utility extension(s) in CardView relevant only to the class in
fileprivate extension SetCardView {
    
    ///
    /// Represents the state of a card in the current game
    ///
    enum CardState {
        // Regular state (i.e. when starting a game)
        case regular
        case matched
        case mismatched
        case selected
        case hinted
    }
    
    ///
    /// The current state of the card
    ///
    var cardState: CardState {
        
        get
        {
            if layer.borderColor == #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1).cgColor
            {
                return .mismatched
            }
            else if layer.borderColor == #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).cgColor
            {
                return .matched
            }
            else if layer.borderColor == #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1).cgColor
            {
                return .selected
            }
            else if layer.borderColor == #colorLiteral(red: 0, green: 0.5173532963, blue: 1, alpha: 1).cgColor
            {
                return .hinted
            }
            else
            {
                return .regular
            }
            
        }
        
        set
        {
            layer.cornerRadius = min(bounds.size.width, bounds.size.height) * 0.1
            switch newValue
            {
                
            case .regular:
                layer.borderWidth = 0.0
                layer.borderColor = UIColor.clear.cgColor
                
            case .matched:
                layer.borderWidth = bounds.width * 0.1
                layer.borderColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1).cgColor
                
            case .mismatched:
                layer.borderWidth = bounds.width * 0.1
                layer.borderColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1).cgColor
                
            case .selected:
                layer.borderWidth = bounds.width * 0.1
                layer.borderColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1).cgColor
            case .hinted:
                layer.borderWidth = bounds.width * 0.1
                layer.borderColor = #colorLiteral(red: 0, green: 0.5173532963, blue: 1, alpha: 1).cgColor
            }
            self.setNeedsDisplay()
        }
    }
}
