import UIKit

/// 模块资源加载工具（支持动态库与静态库）
public final class ModuleResourceLoader {
    
    // MARK: - Cache
    private static var bundleCache = NSCache<NSString, Bundle>()
    
    // MARK: - Public API
    
    /// 通过类型获取模块资源 Bundle（推荐在类型明确的场景使用）
    public static func currentBundle(for type: Any.Type) -> Bundle? {
        let moduleName = moduleName(for: type)
        return currentBundle(for: moduleName)
    }
    
    /// 直接通过模块名获取资源 Bundle（高性能版本）
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
    public static func loadImage(named imageName: String, for type: Any.Type) -> UIImage? {
        return loadImage(named: imageName, forModule: moduleName(for: type))
    }
    
    public static func loadImage(named imageName: String, forModule module: String) -> UIImage? {
        guard let bundle = currentBundle(for: module) else {
            #if DEBUG
            fatalError("🛑 模块 \(module) 未正确配置资源 Bundle")
            #endif
            return nil
        }
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
    
    // MARK: XIB 加载扩展
    public static func loadView<T: UIView>(templateName: String) -> T {
        return loadView(templateName: templateName, forModule: moduleName(for: T.self))
    }
    
    public static func loadView<T: UIView>(templateName: String, forModule module: String) -> T {
        guard let bundle = currentBundle(for: module),
              let view = bundle.loadNibNamed(templateName, owner: nil)?.first as? T else {
            #if DEBUG
            fatalError("""
                🛑 无法加载 \(templateName) 请检查:
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
    
    // MARK: 本地化扩展
    public static func localizedString(forKey key: String,
                                       table: String? = nil,
                                       comment: String = "",
                                       for type: Any.Type) -> String {
        return localizedString(forKey: key, table: table, comment: comment, forModule: moduleName(for: type))
    }
    
    public static func localizedString(forKey key: String,
                                       table: String? = nil,
                                       comment: String = "",
                                       forModule module: String) -> String {
        guard let bundle = currentBundle(for: module) else {
            #if DEBUG
            fatalError("🛑 模块 \(module) 本地化 Bundle 配置错误")
            #endif
            return key
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
