//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class PSPDFSnakeExample: Example {

    override init() {
        super.init()
        title = "Snake Game"
        contentDescription = "Play a quick game of old school snake"
        category = .annotations
        priority = 500
    }

    // MARK: Create document and viewcontroller
    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = createDocument()
        let controller = SnakeViewController(document: document) {
            // Need to show the whole document
            $0.userInterfaceViewMode = .always
        }
        return controller
    }

    func createDocument() -> Document {
        // Set up configuration to create a new document.
        let configuration = Processor.Configuration()

        // Add an empty page
        let emptyPageTemplate = PageTemplate.blank
        let newPageConfiguration = PDFNewPageConfiguration(pageTemplate: emptyPageTemplate) {
            $0.pageMargins = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            $0.pageRotation = .rotation90
        }
        configuration.addNewPage(at: 0, configuration: newPageConfiguration)

        let outputFileURL = FileHelper.temporaryPDFFileURL(prefix: "new-document")
        do {
            // Invoke processor to create new document.
            let processor = Processor(configuration: configuration, securityOptions: nil)
            processor.delegate = self as? ProcessorDelegate
            try processor.write(toFileURL: outputFileURL)
        } catch {
            print("Error while processing document: \(error)")
        }

        let newDocument = Document(url: outputFileURL)
        newDocument.title = "Snake!"
        return newDocument
    }
}

private class SnakeViewController: PDFViewController {

    // MARK: Properties
    let increment = 20
    var xEnd = 70
    var yEnd = 210
    var score = 0

    enum Direction {
        case up
        case down
        case left
        case right
        case none
    }
    var currentDirection = Direction.none
    var previousDirection = Direction.none

    // Used to indicate the current state of the game
    enum GameState {
        case playing
        case paused
    }
    var currentGameState = GameState.paused

    var timer = Timer()

    // We use these properties to get our snake and apple since this way it's easier to work on the same object in various methods
    var snake: PolyLineAnnotation {
        return (self.document?.annotationsForPage(at: 0, type: .polyLine) as! [PolyLineAnnotation]).first!
    }
    var apple: LineAnnotation {
        return (self.document?.annotationsForPage(at: 0, type: .line) as! [LineAnnotation]).first!
    }

    // MARK: Initialization and key commands
    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)
        // Create the snake and the apple
        createSnake()
        createApple()
        // Add the scoreboard
        let scoreButton = UIBarButtonItem(title: "Score: \(score)", style: .plain, target: self, action: nil)
        navigationItem.setRightBarButtonItems([scoreButton], animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the controls here since we need to make sure that the view is already loaded
        addSwipeGestures()
        addKeyCommands()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Shows the instructions on how to control the snake at the beginning
        let instructionsController = UIAlertController(title: "Instructions", message: "To control the snake use your arrow keys on the keyboard or simply swipe in the direction you want to move.", preferredStyle: .alert)
        let start = UIAlertAction(title: "Got it!", style: .default)
        instructionsController.addAction(start)
        self.present(instructionsController, animated: true)
    }

    // Control the snake via the keyboard keys
    private func addKeyCommands() {
        let commands: [UIKeyCommand] = [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(goUp)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(goDown)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(goLeft)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(goRight)),
            UIKeyCommand(input: "p", modifierFlags: [], action: #selector(pause)),
        ]

        for command in commands {
            command.wantsPriorityOverSystemBehavior = true
            command.allowsAutomaticMirroring = false

            addKeyCommand(command)
        }
    }

    // Control the snake via swipe gestures
    func addSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(goLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(goRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(goUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(goDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }

    // MARK: Game States
    // Pause and restart function if you need to step away for a second
    @objc func pause() {
        if currentDirection != .none {
            previousDirection = currentDirection
        }
        currentDirection = .none
        let alertController = UIAlertController(title: "Game Paused", message: "", preferredStyle: .alert)
        let alert = UIAlertAction(title: "Resume", style: .default, handler: { _ in self.restart() })
        alertController.addAction(alert)
        self.present(alertController, animated: true)
    }

    @objc func restart() {
        currentDirection = previousDirection
    }

    // For ending the game and resetting everything to the starting position
    func gameOver() {
        score = 0
        currentDirection = .none
        currentGameState = .paused

        let linesAndPolyLines = document?.annotationsForPage(at: pageIndex, type: [.line, .polyLine])
        document!.remove(annotations: linesAndPolyLines!)
        createApple()
        updateScore()
        createSnake()
    }

    // MARK: Timer
    func setupTimer() {
        if currentGameState == .paused {
            timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
    }

    @objc func timerFired() {
        didBiteSelf()
        didEatApple()
        didLeaveArea()
        goDirection(direction: currentDirection)
    }

    // MARK: Directions
    @objc func goUp() {
        if currentDirection == .down {
            return
        }
        currentDirection = .up
        setupTimer()
    }

    @objc func goDown() {
        if currentDirection == .up {
            return
        }
        currentDirection = .down
        setupTimer()
    }

    @objc func goLeft() {
        if currentDirection == .right {
            return
        }
        currentDirection = .left
        setupTimer()
    }

    @objc func goRight() {
        if currentDirection == .left {
            return
        }
        currentDirection = .right
        setupTimer()
    }

    func goDirection(direction: Direction) {
        var points = snake.points
        currentGameState = .playing
        switch direction {
        case .up:
            yEnd += increment
        case .down:
            yEnd -= increment
        case .left:
            xEnd -= increment
        case .right:
            xEnd += increment
        case .none:
            return
        }

        points?.append(CGPoint(x: xEnd, y: yEnd))
        points?.remove(at: 0)
        snake.points = points
        document?.documentProviderForPage(at: snake.pageIndex)?.annotationManager.update([snake], animated: true)
    }

    // MARK: Create Objects
    func createSnake() {
        let snake = PolyLineAnnotation()
        let xStart = 70
        let yStart = 10
        xEnd = 70
        yEnd = 210
        var points = [CGPoint(x: xStart, y: yStart)]
        for i in 1...10 {
            points.append(CGPoint(x: xStart, y: yStart + increment * i))
        }
        snake.points = points
        snake.color = .blue
        snake.lineWidth = 20
        document?.add(annotations: [snake])
    }

    @objc func createApple () {
        let apple = LineAnnotation()
        // Page boundaries are 600x840
        // Need to create them in 20 increments since it needs to allign exactly with the snake's path
        var randomX = Int.random(in: 0...41)
        var randomY = Int.random(in: 0...29)
        randomX *= 20
        randomY *= 20
        // We need the +10 because otherwise the point could be halfway outside the page, since it's starting point is in the middle of the annotation
        randomX += 10

        // This will create a 20x20 square which is our apple
        apple.points = [CGPoint(x: randomX, y: randomY), CGPoint(x: randomX, y: randomY + 20)]
        apple.lineWidth = 20
        apple.color = .red

        document?.add(annotations: [apple])
    }

    // MARK: Actions
    func didEatApple() {
        guard let lastSnakePoint = snake.points?.last else { return }
        guard let lastApplePoint = apple.points?.last else { return }
        guard let firstApplePoint = apple.points?.first else { return }

        // Since the apple is made from 2 points, we need to check if the head of our snake is between those
        if lastSnakePoint.y <= lastApplePoint.y && lastSnakePoint.y >= firstApplePoint.y && lastSnakePoint.x <= lastApplePoint.x && lastSnakePoint.x >= firstApplePoint.x {
            addTail()
        } else {
            return
        }
        score += 1
        updateScore()
        document?.remove(annotations: (document?.annotationsForPage(at: pageIndex, type: .line))!)
        // Need to create a new one once the old one gets eaten
        createApple()
    }

    func didBiteSelf() {
        guard let snakePoints = snake.points?.count else { return }
        guard let lastSnakePoint = snake.points?.last else { return }

        // Check for each point in the snake. Can't coun't in our own head though!
        for snakePoint in 0...snakePoints - 2 {
            if lastSnakePoint.x == snake.points![snakePoint].x && lastSnakePoint.y == snake.points![snakePoint].y && currentGameState == .playing {
                timer.invalidate()
                let alertController = UIAlertController(title: "Ouch, don't bite yourself!", message: "", preferredStyle: .alert)
                let alert = UIAlertAction(title: "Restart Game", style: .default, handler: { _ in self.gameOver() })
                alertController.addAction(alert)
                self.present(alertController, animated: true)
                currentDirection = .none
            }
        }
    }

    func didLeaveArea() {
        guard let lastSnakePoint = snake.points?.last else { return }
        guard let documentHeight = document?.pageInfoForPage(at: pageIndex)?.size.height else { return }
        guard let documentWidth = document?.pageInfoForPage(at: pageIndex)?.size.width else { return }

        if (lastSnakePoint.x >= documentWidth || lastSnakePoint.x < 0 || lastSnakePoint.y >= documentHeight || lastSnakePoint.y < 0) && currentGameState == .playing {
            timer.invalidate()
            let alertController = UIAlertController(title: "Don't leave the area!", message: "", preferredStyle: .alert)
            let alert = UIAlertAction(title: "Restart Game", style: .default, handler: { _ in self.gameOver() })
            alertController.addAction(alert)
            self.present(alertController, animated: true)
            currentDirection = .none
        }
    }

    func addTail() {
        // This is just a placeholder so the values don’t matter. This point will immediately be removed in `goDirection`.
        snake.points?.insert(CGPoint(x: 0, y: 0), at: 0)
    }

    func updateScore() {
        navigationItem.rightBarButtonItem?.title = "Score: \(score)"
    }
}
