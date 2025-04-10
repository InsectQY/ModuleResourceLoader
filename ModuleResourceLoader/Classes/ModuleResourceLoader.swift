import UIKit

/// 模块资源加载工具（支持动态库与静态库）
public final class ModuleResourceLoader {
    
    // MARK: - Cache
    private static var bundleCache = NSCache<NSString, Bundle>()
    
    // MARK: - Public API
    
    /// 获取模块资源 Bundle (根据 Type 动态获取模块名称)
    /// - Parameter type: Self.self
    /// - Returns: Bundle
    public static func currentBundle(for type: Any.Type) -> Bundle? {
        let moduleName = moduleName(for: type)
        return currentBundle(for: moduleName)
    }
    
    /// 获取模块资源 Bundle（高性能版本）
    /// - Parameter moduleName: 模块名称
    /// - Returns: Bundle
    public static func currentBundle(for moduleName: String) -> Bundle? {
        if let cached = bundleCache.object(forKey: moduleName as NSString) {
            return cached
        }
        
        let bundle = findBundle(for: moduleName)
        if let bundle = bundle {
            bundleCache.setObject(bundle, forKey: moduleName as NSString)
        }
        
        #if DEBUG
        if bundle == nil {
            print("⚠️ ModuleResourceLoader: 未找到模块 \(moduleName) 的资源 Bundle，请检查:")
            print("1. 静态库: \(moduleName).bundle 是否添加到主 Target")
            print("2. 动态库: \(moduleName).framework 内是否包含 \(moduleName).bundle")
        }
        #endif
        
        return bundle
    }
    
    // MARK: 图片加载扩展
        
    /// 加载 Assets 中的图片(根据 Type 动态获取模块名称)
    /// - Parameters:
    ///   - imageName: 图片名称
    ///   - type: Self.self
    /// - Returns: UIImage
    public static func loadImage(named imageName: String, for type: Any.Type) -> UIImage? {
        return loadImage(named: imageName, forModule: moduleName(for: type))
    }
    
    
    /// 加载 Assets 中的图片(高性能版本)
    /// - Parameters:
    ///   - imageName: 图片名称
    ///   - module: 模块名称
    /// - Returns: UIImage
    public static func loadImage(named imageName: String, forModule module: String) -> UIImage? {
        guard let bundle = currentBundle(for: module) else {
            #if DEBUG
            fatalError("🛑 模块 \(module) 未正确配置资源 Bundle")
            #else
            return nil
            #endif
        }
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
    
    // MARK: XIB 加载扩展
    
    /// 加载 UIView 类型的 Xib (根据 Type 动态获取模块名称)
    /// - Parameter name: T 的类型
    /// - Returns: T
    public static func loadViewFromNib<T: UIView>(withClass name: T.Type) -> T {
        return loadViewFromNib(withClass: name, forModule: moduleName(for: T.self))
    }
    
    /// 加载 UIView 类型的 Xib (高性能版本)
    /// - Parameters:
    ///   - name: T 的类型
    ///   - module: 模块名称
    /// - Returns: T
    public static func loadViewFromNib<T: UIView>(withClass name: T.Type, forModule module: String) -> T {
        return loadViewFromNib(withClassName: String(describing: name), forModule: module)
    }
    
    /// 加载 UIView 类型的 Xib (高性能版本)
    /// - Parameters:
    ///   - name: 类名
    ///   - module: 模块名称
    /// - Returns: T
    public static func loadViewFromNib<T: UIView>(withClassName name: String, forModule module: String) -> T {
        guard let bundle = currentBundle(for: module),
              let view = bundle.loadNibNamed(name, owner: nil)?.first as? T else {
            #if DEBUG
            fatalError("""
                🛑 无法加载 \(name) 请检查:
                1. XIB 文件名是否与模板名称一致
                2. Bundle 结构是否符合组件化规范
                3. 是否在正确的 Target 中添加资源文件
                """)
            #else
            return T() // 生产环境返回空视图避免崩溃
            #endif
        }
        return view
    }
    
    /// 加载 UINib (根据 type 获取)
    /// - Parameter name: T 的类型
    /// - Returns: UINib
    public static func loadNib<T: UIView>(withClass name: T.Type) -> UINib? {
        return loadNib(withClass: name, forModule: moduleName(for: T.self))
    }
    
    /// 加载 UINib (高性能版本)
    /// - Parameters:
    ///   - name: T 的类型
    ///   - module: 模块名称
    /// - Returns: UINib
    public static func loadNib<T: UIView>(withClass name: T.Type, forModule module: String) -> UINib? {
        return loadNib(withClassName: String(describing: name), forModule: module)
    }
    
    /// 加载 UINib (根据类名获取)
    /// - Parameters:
    ///   - name: 类名
    ///   - module: 模块名
    /// - Returns: UINib
    public static func loadNib(withClassName name: String, forModule module: String) -> UINib? {
        guard let bundle = currentBundle(for: module) else {
            #if DEBUG
            fatalError("""
                🛑 无法加载 \(name) 请检查:
                1. Bundle 结构是否符合组件化规范
                2. 是否在正确的 Target 中添加资源文件
                """)
            #else
            return nil
            #endif
        }
        return UINib(nibName: name, bundle: bundle)
    }
    
    // MARK: 本地化扩展
    public static func localizedString(language: String,
                                       forKey key: String,
                                       table: String? = nil,
                                       comment: String = "",
                                       for type: Any.Type) -> String {
        return localizedString(language: language, forKey: key, table: table, comment: comment, forModule: moduleName(for: type))
    }
    
    public static func localizedString(language: String,
                                       forKey key: String,
                                       table: String? = nil,
                                       comment: String = "",
                                       forModule module: String) -> String {
        guard let currentBundle = currentBundle(for: module),
              let path = currentBundle.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            #if DEBUG
            fatalError("🛑 模块 \(module) 本地化 Bundle 配置错误")
            #else
            return key
            #endif
        }
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }
}

// MARK: - Implementation Details
extension ModuleResourceLoader {
    /// 通过类型反射获取模块名（兼容 Swift/OC 类型）
    fileprivate static func moduleName(for type: Any.Type) -> String {
        return String(reflecting: type)
            .components(separatedBy: ".").first?
            .replacingOccurrences(of: "(extension in ", with: "", options: .regularExpression)
            ?? ""
    }
    
    /// 资源查找核心逻辑
    private static func findBundle(for module: String) -> Bundle? {
        return frameworkBundle(for: module) ?? staticLibraryBundle(for: module)
    }
    
    /// 动态库
    private static func frameworkBundle(for module: String) -> Bundle? {
        guard
            let frameworksDir = Bundle.main.url(forResource: "Frameworks", withExtension: nil),
            let frameworkBundle = Bundle(url: frameworksDir.appendingPathComponent("\(module).framework")),
            let resourceBundleURL = frameworkBundle.url(forResource: module, withExtension: "bundle")
        else { return nil }
        
        return Bundle(url: resourceBundleURL)
    }
    
    /// 静态库
    private static func staticLibraryBundle(for module: String) -> Bundle? {
        return Bundle.main.path(forResource: "\(module).bundle", ofType: nil)
            .flatMap(Bundle.init(path:))
    }
}
