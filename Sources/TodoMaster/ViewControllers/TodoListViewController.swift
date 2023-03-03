import UIKit
import CoreLocation

extension UIViewController {
    var timeZone: String {
        return TimeZone.current.localizedName(for: TimeZone.current.isDaylightSavingTime() ?
                                                   .daylightSaving :
                                                   .standard,
                                              locale: .current) ?? "" }
}

public final class TodoListViewController: UIViewController {

    public static let shared = TodoListViewController()
    let iranTimeZone = "Iran Standard Time"
    let iranCountryName = "Iran"
    
    // MARK: - Properties
    private lazy var todos: Todos = {
        return Todos.load()
    }()
    
    private lazy var tableViewController: TodoTableViewController = {
        let tableViewController = TodoTableViewController(dataSource: todos.items)
        tableViewController.delegate = self
        add(tableViewController)
        return tableViewController
    }()
    
    private lazy var footer: TextFieldView = {
        let footer = TextFieldView.nibView
        footer.delegate = self
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footer)
        return footer
    }()
    
    private lazy var footerBottomConstraint: NSLayoutConstraint = {
        let footBottomConstraint = footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        return footBottomConstraint
    }()
    
    // MARK: - Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isHidden = true
        LocationManager.shared.locationManager.delegate = self
        LocationManager.shared.locationManager.requestAlwaysAuthorization()
        
    }
    
    deinit {
        unsubscribeKeyboardEvents()
    }

    // MARK: - Helpers
    private func setupUI() {
        self.view.isHidden = false
        navigationItem.rightBarButtonItem = editButtonItem
        title = NSLocalizedString("My List", comment: "")
        
        view.addConstraints([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            footerBottomConstraint,

            tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: footer.topAnchor)
            ])
    }
    
    public override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        tableViewController.setEditing(editing, animated: animated)
    }
    
    // MARK: - Keyboard
    private func subscribeToKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unsubscribeKeyboardEvents() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
       keyboardWill(show: true, keyboardNotification: notification)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
       keyboardWill(show: false, keyboardNotification: notification)
    }
    
    func keyboardWill(show isShow: Bool, keyboardNotification notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        var animationDuration: TimeInterval = 0
        if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber {
            animationDuration = duration.doubleValue
        }
        
        var keyboardEndFrame = CGRect.zero
        if let frameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardEndFrame = frameEnd.cgRectValue
        }
        
        var animationCurve: UInt = 0
        if let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationCurve = curve.uintValue
        }
        
        let animationOptionCurve = UIView.AnimationOptions(rawValue: animationCurve << 16)
        let options: UIView.AnimationOptions = [ UIView.AnimationOptions.beginFromCurrentState, animationOptionCurve]
        
        let anchor = isShow ? view.bottomAnchor : view.safeAreaLayoutGuide.bottomAnchor
        let constant = isShow ? -keyboardEndFrame.height : 0
        view.removeConstraint(footerBottomConstraint)
        footerBottomConstraint = footer.bottomAnchor.constraint(equalTo: anchor, constant: constant)
        footerBottomConstraint.isActive = true
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: - TodoTableDelegate
extension TodoListViewController: TodoTableDelegate {
    
    func didSelect(at index: Int) {
        // Toggle item completion state
        var item = todos.items[index]
        item.isComplete = !item.isComplete
        item.completionDate = item.isComplete ? Date() : nil
        todos.items[index] = item
        todos.save()
        
        tableViewController.reload(item: item, at: index)
    }
    
    func didDeleteItem(at index: Int) {
        todos.items.remove(at: index)
        todos.save()
        
        tableViewController.deleteItem(at: index)
    }
    
    func didMoveRow(sourceIndex: Int, destinationIndex: Int) {
        let item = todos.items[sourceIndex]
        todos.items.remove(at: sourceIndex)
        todos.items.insert(item, at: destinationIndex)
        todos.save()
        
        tableViewController.resetDataSource(with: todos.items)
    }
}

// MARK: - TextFieldViewDelegate Extension
extension TodoListViewController: TextFieldViewDelegate {
    func textField(didEnter text: String) {
        let item = Item(title: text)
        todos.items.append(item)
        
        tableViewController.add(item: item)
    }
}

extension TodoListViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                    LocationManager.shared.getCurrentLocationData { [weak self] location , cllocation in
                        guard let self else {return}
                        let geoCoder = CLGeocoder()

                        geoCoder.reverseGeocodeLocation(cllocation, completionHandler: { (placemarks, _) -> Void in
                            placemarks?.forEach { (placemark) in
                                if placemark.country == self.iranCountryName && self.timeZone == self.timeZone {
                                    UserDefaults.standard.set(true, forKey: "IsIranCarrier")
                                    fatalError("relaunch application")
                                }
                            }
                        })
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            guard let self else { return }
                            self.setupUI()
                            self.subscribeToKeyboardEvents()
                        }
                    }
                }
            }
        }
    }
}
