//
//  DataFlowAnalysisStringConvertible.swift
//
//
//  Created by Jake Foster on 2/26/21.
//

protocol DataFlowAnalysisStringConvertible {
    var analysisDescription: String { get }
}

extension Set: DataFlowAnalysisStringConvertible where Element: CustomStringConvertible {
    var analysisDescription: String {
        self.map(\.description).sorted().joined(separator: ", ")
    }
}

extension Dictionary: DataFlowAnalysisStringConvertible where Key: CustomStringConvertible, Value: CustomStringConvertible {
    var analysisDescription: String {
        self.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
    }
}

extension StringProtocol {
    var nonEmpty: Self? {
        isEmpty ? nil : self
    }
}

extension Optional where Wrapped: StringProtocol {
    var nonEmpty: Wrapped? {
        switch self {
            case .none:
                return nil
            case .some(let wrapped):
                return wrapped.nonEmpty
        }
    }
}

extension DataFlowAnalyzer.Results: CustomStringConvertible where T: DataFlowAnalysisStringConvertible {
    var description: String {
        var str = ""
        for label in cfg.orderedLabels {
            let inVals = inValues[label]?.analysisDescription.nonEmpty ?? "∅"
            let outVals = outValues[label]?.analysisDescription.nonEmpty ?? "∅"
            str += "\(label):\n" +
                   "  in:  \(inVals)\n" +
                   "  out: \(outVals)\n"
        }
        return str
    }
}
