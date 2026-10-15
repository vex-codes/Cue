import Foundation
import AppKit
import SwiftUI
import JavaScriptCore

class CalculatorEngine {
    
    /// Attempts to evaluate a query as a math expression or currency conversion.
    /// Returns nil if the query is not a valid expression.
    static func evaluate(_ query: String) -> CalculatorResult? {
        // Try currency conversion first
        if let currencyAnswer = evaluateCurrency(query) {
            return makeResult(expression: query, answer: currencyAnswer)
        }
        
        // Try math expression
        if let mathAnswer = evaluateMath(query) {
            return makeResult(expression: query, answer: mathAnswer)
        }
        
        return nil
    }
    
    // MARK: - Math Evaluation
    
    static func evaluateMath(_ query: String) -> String? {
        // Must contain at least one operator and one digit
        let hasOperator = query.contains(where: { "+-*/".contains($0) })
        let hasDigit = query.contains(where: { $0.isNumber })
        guard hasOperator && hasDigit else { return nil }
        
        // Sanitize: only allow math characters
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/() ")
        guard query.unicodeScalars.allSatisfy({ allowed.contains($0) || $0 == " " }) else { return nil }
        
        // Use JavaScriptCore for safe evaluation (no crashes on invalid input)
        guard let context = JSContext() else { return nil }
        
        // Disable access to anything dangerous
        context.exceptionHandler = { _, _ in }
        
        guard let result = context.evaluateScript(query) else { return nil }
        
        if result.isUndefined || result.isNull {
            return nil
        }
        
        let doubleValue = result.toDouble()
        
        // Check for NaN/Infinity
        guard !doubleValue.isNaN && !doubleValue.isInfinite else { return nil }
        
        // Format nicely
        if doubleValue == floor(doubleValue) && abs(doubleValue) < 1e15 {
            return String(format: "%.0f", doubleValue)
        } else {
            // Up to 6 significant digits
            let formatted = String(format: "%.6g", doubleValue)
            return formatted
        }
    }
    
    // MARK: - Currency Conversion
    
    static func evaluateCurrency(_ query: String) -> String? {
        let pattern = #"(\d+\.?\d*)\s*(usd|eur|gbp|jpy|cad|aud|inr|chf|krw|mxn)\s+to\s+(usd|eur|gbp|jpy|cad|aud|inr|chf|krw|mxn)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) else {
            return nil
        }
        
        guard let amountRange = Range(match.range(at: 1), in: query),
              let fromRange = Range(match.range(at: 2), in: query),
              let toRange = Range(match.range(at: 3), in: query) else {
            return nil
        }
        
        let amount = Double(query[amountRange]) ?? 0
        let from = String(query[fromRange]).uppercased()
        let to = String(query[toRange]).uppercased()
        
        // Rates: how many units of each currency per 1 USD (approximate offline rates)
        let ratesPerUSD: [String: Double] = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 149.5,
            "CAD": 1.36,
            "AUD": 1.53,
            "INR": 83.1,
            "CHF": 0.88,
            "KRW": 1320.0,
            "MXN": 17.15
        ]
        
        guard let fromRate = ratesPerUSD[from], let toRate = ratesPerUSD[to] else { return nil }
        
        // Convert: source → USD → target
        let inUSD = amount / fromRate
        let result = inUSD * toRate
        
        let formatted = String(format: "%.2f", result)
        return "\(formatted) \(to)"
    }
    
    // MARK: - Helper
    
    private static func makeResult(expression: String, answer: String) -> CalculatorResult {
        let icon: NSImage
        if let symbolImage = NSImage(systemSymbolName: "equal.circle.fill", accessibilityDescription: "Calculator") {
            let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .medium)
            icon = symbolImage.withSymbolConfiguration(config) ?? symbolImage
            icon.size = NSSize(width: 128, height: 128)
        } else {
            icon = NSImage()
        }
        
        return CalculatorResult(
            expression: expression,
            answer: answer,
            icon: icon,
            averageColor: Color(hue: 0.35, saturation: 0.7, brightness: 0.8)
        )
    }
}
