/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit
import CoreMotion

let maxPlayerAcceleration: CGFloat = 400
let maxPlayerSpeed: CGFloat = 200
let bordercollisionDamping: CGFloat = 0.4
let maxHealth = 100
let healthBarWidth: CGFloat = 40
let healthBarHeight: CGFloat = 4
let degreesToRadians = CGFloat.pi / 180
let radiansToDegrees = 180 / CGFloat.pi

class GameScene: SKScene {
  
  var accelerometerX: UIAccelerationValue = 0
  var accelerometerY: UIAccelerationValue = 0
  var playerAcceleration = CGVector(dx: 0, dy: 0)
  var playerVelocity = CGVector(dx: 0, dy: 0)
  var lastUpdateTime: CFTimeInterval = 0
  let playerHealthBar = SKSpriteNode()
  let cannonHealthBar = SKSpriteNode()
  var playerHP = maxHealth
  var cannonHP = maxHealth
  var playerAngle: CGFloat = 0
  var previousAngle: CGFloat = 0

  let playerSprite = SKSpriteNode(imageNamed: "Player")
  let cannonSprite = SKSpriteNode(imageNamed: "Cannon")
  let turretSprite = SKSpriteNode(imageNamed: "Turret")
  
  let motionManager = CMMotionManager()

  override func didMove(to view: SKView) {
    // set scene size to match view
    size = view.bounds.size
    
    backgroundColor = SKColor(red: 94.0/255, green: 63.0/255, blue: 107.0/255, alpha: 1)
    
    cannonSprite.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(cannonSprite)
    
    turretSprite.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(turretSprite)
    
    playerSprite.position = CGPoint(x: size.width - 50, y: 60)
    addChild(playerSprite)
    
    addChild(playerHealthBar)
    
    addChild(cannonHealthBar)
    
    cannonHealthBar.position = CGPoint(
      x: cannonSprite.position.x,
      y: cannonSprite.position.y - cannonSprite.size.height/2 - 10
    )
    
    updateHealthBar(playerHealthBar, withHealthPoints: playerHP)
    updateHealthBar(cannonHealthBar, withHealthPoints: cannonHP)
    
    startMonitoringAcceleration()
  }
  
  override func update(_ currentTime: TimeInterval) {
    // to compute velocities we need delta time to multiply by points per second
    // SpriteKit returns the currentTime, delta is computed as last called time - currentTime
    let deltaTime = max(1.0/30, currentTime - lastUpdateTime)
    lastUpdateTime = currentTime
    
    updatePlayerAccelerationFromMotionManager()
    updatePlayer(deltaTime)
    updateTurret(deltaTime)

  }
  
  func startMonitoringAcceleration() {
    guard motionManager.isAccelerometerAvailable else { return }
    motionManager.startAccelerometerUpdates()
    print("accelerometer updates on...")
  }
  
  func stopMonitoringAcceleration() {
    guard motionManager.isAccelerometerAvailable else { return }
    motionManager.stopAccelerometerUpdates()
    print("accelerometer updates off...")
  }
  
  func updatePlayerAccelerationFromMotionManager() {
    guard let acceleration = motionManager.accelerometerData?.acceleration else { return }
    let filterFactor = 0.75
    
    accelerometerX = acceleration.x * filterFactor + accelerometerX * (1 - filterFactor)
    accelerometerY = acceleration.y * filterFactor + accelerometerY * (1 - filterFactor)
    
    playerAcceleration.dx = CGFloat(accelerometerY) * -maxPlayerAcceleration
    playerAcceleration.dy = CGFloat(accelerometerX) * maxPlayerAcceleration
  }
  
  func updatePlayer(_ dt: CFTimeInterval) {
    playerVelocity.dx = playerVelocity.dx + playerAcceleration.dx * CGFloat(dt)
    playerVelocity.dy = playerVelocity.dy + playerAcceleration.dy * CGFloat(dt)
    
    playerVelocity.dx = max(-maxPlayerSpeed, min(maxPlayerSpeed, playerVelocity.dx))
    playerVelocity.dy = max(-maxPlayerSpeed, min(maxPlayerSpeed, playerVelocity.dy))
    
    var newX = playerSprite.position.x + playerVelocity.dx * CGFloat(dt)
    var newY = playerSprite.position.y + playerVelocity.dy * CGFloat(dt)

    var collidedWithVerticalBorder = false
    var collidedWithHorizontalBorder = false
    
    if newX < 0 {
        newX = 0
        collidedWithVerticalBorder = true
    } else if newX > size.width {
        newX = size.width
        collidedWithVerticalBorder = true
    }
    
    if newY < 0 {
        newY = 0
        collidedWithHorizontalBorder = true
    } else if newY > size.height {
        newY = size.height
        collidedWithHorizontalBorder = true
    }
    
    if collidedWithVerticalBorder {
        playerAcceleration.dx = -playerAcceleration.dx * bordercollisionDamping
        playerVelocity.dx = -playerVelocity.dx * bordercollisionDamping
        playerAcceleration.dy = playerAcceleration.dy * bordercollisionDamping
        playerVelocity.dy = playerVelocity.dy * bordercollisionDamping
    }
    
    if collidedWithHorizontalBorder {
        playerAcceleration.dx = playerAcceleration.dx * bordercollisionDamping
        playerVelocity.dx = playerVelocity.dx * bordercollisionDamping
        playerAcceleration.dy = -playerAcceleration.dy * bordercollisionDamping
        playerVelocity.dy = -playerVelocity.dy * bordercollisionDamping
    }



    
    playerSprite.position = CGPoint(x: newX, y: newY)
    
    playerHealthBar.position = CGPoint(
      x: playerSprite.position.x,
      y: playerSprite.position.y - playerSprite.size.height/2 - 15
    )
    
    let rotationThreshold: CGFloat = 40
    let rotationBlendFactor: CGFloat = 0.2
    
    let speed = sqrt(playerVelocity.dx * playerVelocity.dx + playerVelocity.dy * playerVelocity.dy)
    if speed > rotationThreshold {
        let angle = atan2(playerVelocity.dy, playerVelocity.dx)
        
        // did angle flip from +π to -π, or -π to +π?
        if angle - previousAngle > CGFloat.pi {
            playerAngle += 2 * CGFloat.pi
        } else if previousAngle - angle > CGFloat.pi {
            playerAngle -= 2 * CGFloat.pi
        }
        
        previousAngle = angle
        playerAngle = angle * rotationBlendFactor + playerAngle * (1 - rotationBlendFactor)
        playerSprite.zRotation = playerAngle - 90 * degreesToRadians
    }





  }
    
    func updateTurret(_ dt: CFTimeInterval) {
        let deltaX = playerSprite.position.x - turretSprite.position.x
        let deltaY = playerSprite.position.y - turretSprite.position.y
        let angle = atan2(deltaY, deltaX)
        
        turretSprite.zRotation = angle - 90 * degreesToRadians
    }

  
  func updateHealthBar(_ node: SKSpriteNode, withHealthPoints hp: Int) {
    let barSize = CGSize(width: healthBarWidth, height: healthBarHeight);
    
    let fillColor = UIColor(red: 113.0/255, green: 202.0/255, blue: 53.0/255, alpha:1)
    let borderColor = UIColor(red: 35.0/255, green: 28.0/255, blue: 40.0/255, alpha:1)
    
    // create drawing context
    UIGraphicsBeginImageContextWithOptions(barSize, false, 0)
    guard let context = UIGraphicsGetCurrentContext() else { return }
    
    // draw the outline for the health bar
    borderColor.setStroke()
    let borderRect = CGRect(origin: CGPoint.zero, size: barSize)
    context.stroke(borderRect, width: 1)
    
    // draw the health bar with a colored rectangle
    fillColor.setFill()
    let barWidth = (barSize.width - 1) * CGFloat(hp) / CGFloat(maxHealth)
    let barRect = CGRect(x: 0.5, y: 0.5, width: barWidth, height: barSize.height - 1)
    context.fill(barRect)
    
    // extract image
    guard let spriteImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
    UIGraphicsEndImageContext()
    
    // set sprite texture and size
    node.texture = SKTexture(image: spriteImage)
    node.size = barSize
  }
  
  deinit {
    stopMonitoringAcceleration()
  }
}
