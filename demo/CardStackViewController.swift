import UIKit

class CardStackViewController: UIViewController {
    private var cards: [CardView] = []
    private var currentIndex = 0
    
    // 示例数据
    private let titles = [
        "中医入门第一讲",
        "中医入门第二讲",
        "中医入门第三讲",
        "中医入门第四讲",
        "中医入门第五讲"
    ]
    
    private var isAnimating = false
    private var containerView: UIView!
    private let cardWidth: CGFloat = 280 // 卡片宽度
    private let cardSpacing: CGFloat = 40 // 露出的宽度
    private let cardScaleRatio: CGFloat = 0.08 // 每张卡片的缩放比例
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGesture()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGray6
        
        // 创建容器视图
        containerView = UIView()
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // 初始化卡片
        setupCards()
    }
    
    private func setupCards() {
        // 清除现有卡片
        cards.forEach { $0.removeFromSuperview() }
        cards.removeAll()
        
        // 创建3张卡片
        for i in 0..<3 {
            let index = (currentIndex + i) % titles.count
            let card = CardView()
            card.titleLabel.text = titles[index]
            containerView.addSubview(card)
            cards.append(card)
            
            card.translatesAutoresizingMaskIntoConstraints = false
            
            // 设置卡片约束
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: cardWidth),
                card.heightAnchor.constraint(equalToConstant: 180),
                card.topAnchor.constraint(equalTo: containerView.topAnchor),
                card.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            ])
            
            updateCardTransform(card: card, index: i, animated: false)
        }
    }
    
    private func updateCardTransform(card: CardView, index: Int, animated: Bool = true) {
        let scale = 1 - (CGFloat(index) * cardScaleRatio)
        let translation = CGFloat(index) * cardSpacing
        
        let transform = CGAffineTransform.identity
            .translatedBy(x: translation, y: 0)
            .scaledBy(x: scale, y: scale)
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                card.transform = transform
            }
        } else {
            card.transform = transform
        }
        
        card.layer.zPosition = -CGFloat(index)
    }
    
    private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isAnimating, let firstCard = cards.first else { return }
        let translation = gesture.translation(in: containerView)
        
        switch gesture.state {
        case .changed:
            // 禁止右滑
            if translation.x > 0 {
                return
            }
            // 获取第一张卡片的初始transform
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            let translation = CGAffineTransform(translationX: translation.x, y: 0)
            firstCard.transform = scale.concatenating(translation)
            
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: containerView)
            let translation = gesture.translation(in: containerView)
            
            if translation.x < -50 || velocity.x < -500 {
                animateCardTransition()
            } else {
                // 回弹动画
                updateCardTransform(card: firstCard, index: 0)
            }
            
        default:
            break
        }
    }
    
    private func animateCardTransition() {
        isAnimating = true
        guard let firstCard = cards.first else { return }
        
        // 准备新卡片
        let newIndex = (currentIndex + 2) % titles.count
        let newCard = CardView()
        newCard.titleLabel.text = titles[newIndex]
        newCard.alpha = 0
        containerView.addSubview(newCard)
        
        newCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newCard.widthAnchor.constraint(equalToConstant: cardWidth),
            newCard.heightAnchor.constraint(equalToConstant: 180),
            newCard.topAnchor.constraint(equalTo: containerView.topAnchor),
            newCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        // 设置新卡片的初始位置
        updateCardTransform(card: newCard, index: 2, animated: false)
        
        // 同步动画：第一张卡片滑出，其他卡片移动
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
            // 第一张卡片滑出
            firstCard.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
            firstCard.alpha = 0
            
            // 其他卡片同步移动
            if self.cards.count > 1 {
                self.updateCardTransform(card: self.cards[1], index: 0, animated: false)
            }
            if self.cards.count > 2 {
                self.updateCardTransform(card: self.cards[2], index: 1, animated: false)
            }
            newCard.alpha = 1
        }) { _ in
            // 移除第一张卡片
            firstCard.removeFromSuperview()
            self.cards.removeFirst()
            
            // 更新索引和卡片数组
            self.currentIndex = (self.currentIndex + 1) % self.titles.count
            self.cards.append(newCard)
            self.isAnimating = false
        }
    }
}

// MARK: - CardView
class CardView: UIView {
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    let playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 添加阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.2
        
        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(playButton)
        containerView.addSubview(titleLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.6),
            
            playButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }
}
