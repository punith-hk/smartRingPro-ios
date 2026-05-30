import UIKit

enum BodyPart: String {
    case head = "Head"
    case neck = "Throat"
    case leftHand = "Left Hand"
    case rightHand = "Right Hand"
    case chest = "Chest"
    case stomach = "Stomach"
    case pelvis = "Pelvis"
    case leftLeg = "Left Leg"
    case rightLeg = "Right Leg"
    
    var displayName: String {
        return self.rawValue
    }
}

enum Gender {
    case male
    case female
}

protocol HumanBodyViewDelegate: AnyObject {
    func humanBodyView(_ view: HumanBodyView, didTapBodyPart part: BodyPart)
}

final class HumanBodyView: UIView {
    
    weak var delegate: HumanBodyViewDelegate?
    
    var gender: Gender = .male {
        didSet {
            updateBodyForGender()
        }
    }
    
    // Body part views
    private let headView = UIView()
    private let neckView = UIView()
    private let leftHandView = UIView()
    private let rightHandView = UIView()
    private let upperBodyView = UIView() // Chest
    private let middleBodyView = UIView() // Stomach
    private let centerBodyView = UIView() // Pelvis
    private let leftBottomView = UIView() // Left hip triangle
    private let rightBottomView = UIView() // Right hip triangle
    private let leftLegView = UIView()
    private let rightLegView = UIView()
    
    // Female-specific views
    private let femaleHairView = UIView()
    
    // Body color - orange
    private let bodyColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
    // Hair color - brown
    private let hairColor = UIColor(red: 0.55, green: 0.35, blue: 0.16, alpha: 1.0)
    // Selected color - pink
    private let selectedColor = UIColor(red: 1.0, green: 0.45, blue: 0.5, alpha: 1.0)
    
    // Track selected parts
    private var selectedParts: Set<String> = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBodyParts()
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBodyParts()
        setupGestureRecognizers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBodyLayout()
    }
    
    private func setupBodyParts() {
        backgroundColor = .clear
        
        // Add female hair first so it's behind everything
        femaleHairView.backgroundColor = hairColor
        femaleHairView.isUserInteractionEnabled = true
        femaleHairView.layer.masksToBounds = true
        femaleHairView.isHidden = true
        addSubview(femaleHairView)
        
        // Setup all body part views (on top of hair)
        let bodyParts = [
            headView, neckView, leftHandView, rightHandView,
            upperBodyView, middleBodyView, centerBodyView,
            leftBottomView, rightBottomView,
            leftLegView, rightLegView
        ]
        
        for part in bodyParts {
            part.backgroundColor = bodyColor
            part.isUserInteractionEnabled = true
            addSubview(part)
        }
        
        // Head is circular
        headView.layer.masksToBounds = true
        
        // Slight rounding on arms and legs
        leftHandView.layer.cornerRadius = 3
        rightHandView.layer.cornerRadius = 3
        leftLegView.layer.cornerRadius = 3
        rightLegView.layer.cornerRadius = 3
    }
    

    
    private func updateBodyLayout() {
        let width = bounds.width
        let height = bounds.height
        
        // Proportions based on Android screenshot analysis
        let centerX = width / 2
        let bodyWidth: CGFloat = 120
        let handWidth: CGFloat = 40 // Reduced from 50
        
        // Head - match female head size, moved down slightly
        let headSize: CGFloat = 95 // Match female hair size
        let headY: CGFloat = 15 // Back to original position
        headView.frame = CGRect(
            x: centerX - headSize / 2,
            y: headY,
            width: headSize,
            height: headSize
        )
        headView.layer.cornerRadius = headSize / 2
        
        // Female hair (bell-shaped behind head and neck)
        if gender == .female {
            let hairWidth: CGFloat = 120 // Wider at top
            let hairHeight: CGFloat = 170 // Covers head and neck
            femaleHairView.frame = CGRect(
                x: centerX - hairWidth / 2,
                y: headY - 40,
                width: hairWidth,
                height: hairHeight
            )
            createFemaleHairShape()
        }
        
        // Neck - overlaps with head by 3px
        let neckWidth: CGFloat = 40
        let neckHeight: CGFloat = 20 // Reduced from 30
        let neckY = headY + headSize - 3 // Overlap with head
        neckView.frame = CGRect(
            x: centerX - neckWidth / 2,
            y: neckY,
            width: neckWidth,
            height: neckHeight
        )
        
        // Gap between neck and chest
        let neckGap: CGFloat = 3
        
        // Upper Body (Chest)
        let chestHeight: CGFloat = 85
        let chestY = neckY + neckHeight + neckGap
        upperBodyView.frame = CGRect(
            x: centerX - bodyWidth / 2,
            y: chestY,
            width: bodyWidth,
            height: chestHeight
        )
        if gender == .female {
            createFemaleChestShape()
        } else {
            upperBodyView.layer.mask = nil
        }
        
        // Gap between chest and stomach
        let bodyGap: CGFloat = 3
        
        // Middle Body (Stomach) - match chest height
        let stomachHeight: CGFloat = 85
        let stomachY = chestY + chestHeight + bodyGap
        middleBodyView.frame = CGRect(
            x: centerX - bodyWidth / 2,
            y: stomachY,
            width: bodyWidth,
            height: stomachHeight
        )
        if gender == .female {
            createFemaleStomachShape()
        } else {
            middleBodyView.layer.mask = nil
        }
        
        // Gap before pelvis
        let pelvisGap: CGFloat = 3
        
        // Center Body (Pelvis) - inverted triangle
        let pelvisHeight: CGFloat = 60 // Reduced from 60
        let pelvisY = stomachY + stomachHeight + pelvisGap
        centerBodyView.frame = CGRect(
            x: centerX - bodyWidth / 2,
            y: pelvisY,
            width: bodyWidth,
            height: pelvisHeight
        )
        // Create proper inverted triangle shape for pelvis
        createPelvisShape()
        
        // Arms - thinner and match chest+stomach height exactly (plus gap)
        let handGap: CGFloat = 3 // Gap between arm and body
        let armHeight = chestHeight + stomachHeight + bodyGap
        
        // Left Hand
        leftHandView.frame = CGRect(
            x: centerX - bodyWidth / 2 - handWidth - handGap,
            y: chestY,
            width: handWidth,
            height: armHeight
        )
        
        // Right Hand
        rightHandView.frame = CGRect(
            x: centerX + bodyWidth / 2 + handGap,
            y: chestY,
            width: handWidth,
            height: armHeight
        )
        
        // Hip triangles (left and right bottom parts)
        let legWidth: CGFloat = 52
        let hipTriangleHeight: CGFloat = 55
        let hipOverlap: CGFloat = 52 // Move up slightly more (increased from 48)
        let hipY = pelvisY + pelvisHeight - hipOverlap
        let legGap: CGFloat = 3
        
        // Left bottom triangle - width matches leg, sits exactly on left leg
        leftBottomView.frame = CGRect(
            x: centerX - legGap - legWidth,
            y: hipY,
            width: legWidth,
            height: hipTriangleHeight
        )
        createLeftHipTriangle()
        
        // Right bottom triangle - width matches leg, sits exactly on right leg
        rightBottomView.frame = CGRect(
            x: centerX + legGap,
            y: hipY,
            width: legWidth,
            height: hipTriangleHeight
        )
        createRightHipTriangle()
        
        // Legs - start directly below hip triangles
        let legHeight: CGFloat = 160 // Increased from 140
        let legY = hipY + hipTriangleHeight
        
        // Left Leg
        leftLegView.frame = CGRect(
            x: centerX - legGap - legWidth,
            y: legY,
            width: legWidth,
            height: legHeight
        )
        
        // Right Leg
        rightLegView.frame = CGRect(
            x: centerX + legGap,
            y: legY,
            width: legWidth,
            height: legHeight
        )
    }
    
    private func createLeftHipTriangle() {
        // Remove old layers
        leftBottomView.layer.sublayers?.removeAll()
        leftBottomView.layer.mask = nil
        
        let width = leftBottomView.bounds.width
        let height = leftBottomView.bounds.height
        
        // Right-angled triangle pointing UP - bottom-left to top-left to bottom-right
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: height)) // Bottom-left
        path.addLine(to: CGPoint(x: 0, y: 0)) // Top-left (apex)
        path.addLine(to: CGPoint(x: width, y: height)) // Bottom-right
        path.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        leftBottomView.layer.mask = maskLayer
    }
    
    private func createRightHipTriangle() {
        // Remove old layers
        rightBottomView.layer.sublayers?.removeAll()
        rightBottomView.layer.mask = nil
        
        let width = rightBottomView.bounds.width
        let height = rightBottomView.bounds.height
        
        // Right-angled triangle pointing UP - bottom-left to top-right to bottom-right (mirror)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: height)) // Bottom-left
        path.addLine(to: CGPoint(x: width, y: 0)) // Top-right (apex)
        path.addLine(to: CGPoint(x: width, y: height)) // Bottom-right
        path.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        rightBottomView.layer.mask = maskLayer
    }
    
    private func createPelvisShape() {
        // Remove old layers
        centerBodyView.layer.sublayers?.removeAll()
        centerBodyView.layer.mask = nil
        
        let width = centerBodyView.bounds.width
        let height = centerBodyView.bounds.height
        
        // Create inverted triangle with sharp bottom point
        let path = UIBezierPath()
        
        // Top edge (full width - connects to stomach)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        
        // Right side - tapers to sharp point at bottom center
        path.addLine(to: CGPoint(x: width * 0.5, y: height))
        
        // Left side - from center point back to top left
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()
        
        // Apply as mask
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        centerBodyView.layer.mask = maskLayer
    }
    
    private func createFemaleHairShape() {
        // Remove old layers
        femaleHairView.layer.sublayers?.removeAll()
        femaleHairView.layer.mask = nil
        
        let width = femaleHairView.bounds.width
        let height = femaleHairView.bounds.height
        
        // Bell shape - curves inward at top (wider at bottom)
        let path = UIBezierPath()
        
        // Start at bottom left
        path.move(to: CGPoint(x: width * 0.15, y: height))
        
        // Left side - curve outward
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height * 0.4),
            controlPoint: CGPoint(x: 0, y: height * 0.7)
        )
        
        // Top arc (narrower at top)
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.4),
            controlPoint: CGPoint(x: width / 2, y: 0)
        )
        
        // Right side - curve outward
        path.addQuadCurve(
            to: CGPoint(x: width * 0.85, y: height),
            controlPoint: CGPoint(x: width, y: height * 0.7)
        )
        
        // Bottom edge (wider)
        path.addLine(to: CGPoint(x: width * 0.15, y: height))
        
        path.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        femaleHairView.layer.mask = maskLayer
    }
    
    private func createFemaleChestShape() {
        // Remove old layers
        upperBodyView.layer.sublayers?.removeAll()
        upperBodyView.layer.mask = nil
        
        let width = upperBodyView.bounds.width
        let height = upperBodyView.bounds.height
        
        // Chest shape: wider at top (full width), narrower at bottom (curves inward)
        let path = UIBezierPath()
        
        // Start at top left - full width
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge - full width
        path.addLine(to: CGPoint(x: width, y: 0))
        
        // Right side - curves inward toward bottom
        path.addLine(to: CGPoint(x: width * 0.85, y: height))
        
        // Bottom edge - narrower
        path.addLine(to: CGPoint(x: width * 0.15, y: height))
        
        // Left side - curves inward toward bottom
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        upperBodyView.layer.mask = maskLayer
    }
    
    private func createFemaleStomachShape() {
        // Remove old layers
        middleBodyView.layer.sublayers?.removeAll()
        middleBodyView.layer.mask = nil
        
        let width = middleBodyView.bounds.width
        let height = middleBodyView.bounds.height
        
        // Stomach shape: narrower at top (waist), wider at bottom (hips)
        let path = UIBezierPath()
        
        // Start at top left - narrower
        path.move(to: CGPoint(x: width * 0.15, y: 0))
        
        // Top edge - narrower (waist)
        path.addLine(to: CGPoint(x: width * 0.85, y: 0))
        
        // Right side - curves outward toward bottom
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Bottom edge - wider (full width)
        path.addLine(to: CGPoint(x: 0, y: height))
        
        // Left side - curves outward toward bottom
        path.addLine(to: CGPoint(x: width * 0.15, y: 0))
        
        path.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        middleBodyView.layer.mask = maskLayer
    }
    
    private func updateBodyForGender() {
        femaleHairView.isHidden = (gender == .male)
        setNeedsLayout()
    }
    
    func updateSelectedParts(_ parts: [String]) {
        selectedParts = Set(parts)
        updateBodyPartColors()
    }
    
    private func updateBodyPartColors() {
        let bodyParts: [(view: UIView, name: String)] = [
            (headView, "Head"),
            (neckView, "Throat"),
            (leftHandView, "Left Hand"),
            (rightHandView, "Right Hand"),
            (upperBodyView, "Chest"),
            (middleBodyView, "Stomach"),
            (centerBodyView, "Pelvis"),
            (leftLegView, "Left Leg"),
            (rightLegView, "Right Leg"),
            (leftBottomView, "Left Leg"), // Hip triangle also for left leg
            (rightBottomView, "Right Leg") // Hip triangle also for right leg
        ]
        
        for (view, name) in bodyParts {
            let isSelected = selectedParts.contains(name)
            view.backgroundColor = isSelected ? selectedColor : bodyColor
        }
    }
    
    private func setupGestureRecognizers() {
        let bodyPartData: [(view: UIView, part: BodyPart)] = [
            (headView, .head),
            (neckView, .neck),
            (leftHandView, .leftHand),
            (rightHandView, .rightHand),
            (upperBodyView, .chest),
            (middleBodyView, .stomach),
            (centerBodyView, .pelvis),
            (leftBottomView, .leftLeg), // Part of left leg
            (rightBottomView, .rightLeg), // Part of right leg
            (leftLegView, .leftLeg),
            (rightLegView, .rightLeg)
        ]
        
        for (view, part) in bodyPartData {
            let tap = UITapGestureRecognizer(target: self, action: #selector(bodyPartTapped(_:)))
            view.addGestureRecognizer(tap)
            view.tag = part.hashValue
        }
    }
    
    @objc private func bodyPartTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        
        // Find which body part was tapped
        let bodyParts: [BodyPart] = [.head, .neck, .leftHand, .rightHand, .chest, .stomach, .pelvis, .leftLeg, .rightLeg]
        
        for part in bodyParts {
            if tappedView == getView(for: part) {
                // Visual feedback
                animateTap(on: tappedView)
                delegate?.humanBodyView(self, didTapBodyPart: part)
                break
            }
        }
    }
    
    private func getView(for part: BodyPart) -> UIView {
        switch part {
        case .head: return headView
        case .neck: return neckView
        case .leftHand: return leftHandView
        case .rightHand: return rightHandView
        case .chest: return upperBodyView
        case .stomach: return middleBodyView
        case .pelvis: return centerBodyView
        case .leftLeg: return leftLegView
        case .rightLeg: return rightLegView
        }
    }
    
    private func animateTap(on view: UIView) {
        let originalColor = view.backgroundColor
        UIView.animate(withDuration: 0.1, animations: {
            view.backgroundColor = self.bodyColor.withAlphaComponent(0.6)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                view.backgroundColor = originalColor
            }
        }
    }
}
