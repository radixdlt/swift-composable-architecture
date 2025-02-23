#if canImport(ComposableArchitectureMacros)
  import ComposableArchitectureMacros
  import MacroTesting
  import SwiftSyntaxMacros
  import SwiftSyntaxMacrosTestSupport
  import XCTest

  final class ObservableStateMacroTests: MacroBaseTestCase {
    override func invokeTest() {
      withMacroTesting {
        super.invokeTest()
      }
    }

    func testAvailability() {
      assertMacro {
        """
        @ObservableState
        @available(iOS 18, *)
        struct State {
          var count = 0
        }
        """
      } expansion: {
        #"""
        @available(iOS 18, *)
        struct State {
          var count = 0 {
            @storageRestrictions(initializes: _count)
            init(initialValue) {
              _count = initialValue
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.count)
              return _count
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.count, &_count, newValue, _$isIdentityEqual)
            }
            _modify {
              let oldValue = _$observationRegistrar.willModify(self, keyPath: \.count, &_count)
              defer {
                _$observationRegistrar.didModify(self, keyPath: \.count, &_count, oldValue, _$isIdentityEqual)
              }
              yield &_count
            }
          }

          var _$observationRegistrar = ComposableArchitecture.ObservationStateRegistrar()

          var _$id: ComposableArchitecture.ObservableStateID {
            _$observationRegistrar.id
          }

          mutating func _$willModify() {
            _$observationRegistrar._$willModify()
          }
        }
        """#
      }
    }

    func testObservableState() throws {
      assertMacro {
        #"""
        @ObservableState
        struct State {
          var count = 0
        }
        """#
      } expansion: {
        #"""
        struct State {
          var count = 0 {
            @storageRestrictions(initializes: _count)
            init(initialValue) {
              _count = initialValue
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.count)
              return _count
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.count, &_count, newValue, _$isIdentityEqual)
            }
            _modify {
              let oldValue = _$observationRegistrar.willModify(self, keyPath: \.count, &_count)
              defer {
                _$observationRegistrar.didModify(self, keyPath: \.count, &_count, oldValue, _$isIdentityEqual)
              }
              yield &_count
            }
          }

          var _$observationRegistrar = ComposableArchitecture.ObservationStateRegistrar()

          var _$id: ComposableArchitecture.ObservableStateID {
            _$observationRegistrar.id
          }

          mutating func _$willModify() {
            _$observationRegistrar._$willModify()
          }
        }
        """#
      }
    }

    func testObservableStateIgnored() throws {
      assertMacro {
        #"""
        @ObservableState
        struct State {
          @ObservationStateIgnored
          var count = 0
        }
        """#
      } expansion: {
        """
        struct State {
          var count = 0

          var _$observationRegistrar = ComposableArchitecture.ObservationStateRegistrar()

          var _$id: ComposableArchitecture.ObservableStateID {
            _$observationRegistrar.id
          }

          mutating func _$willModify() {
            _$observationRegistrar._$willModify()
          }
        }
        """
      }
    }

    func testObservableState_Enum() {
      assertMacro {
        """
        @ObservableState
        enum Path {
          case feature1(Feature1.State)
          case feature2(Feature2.State)
        }
        """
      } expansion: {
        """
        enum Path {
          case feature1(Feature1.State)
          case feature2(Feature2.State)

          var _$id: ComposableArchitecture.ObservableStateID {
            switch self {
            case let .feature1(state):
              return ._$id(for: state)._$tag(0)
            case let .feature2(state):
              return ._$id(for: state)._$tag(1)
            }
          }

          mutating func _$willModify() {
            switch self {
            case var .feature1(state):
              ComposableArchitecture._$willModify(&state)
              self = .feature1(state)
            case var .feature2(state):
              ComposableArchitecture._$willModify(&state)
              self = .feature2(state)
            }
          }
        }
        """
      }
    }

    func testObservableState_Enum_Label() {
      assertMacro {
        """
        @ObservableState
        enum Path {
          case feature1(state: String)
        }
        """
      } expansion: {
        """
        enum Path {
          case feature1(state: String)

          var _$id: ComposableArchitecture.ObservableStateID {
            switch self {
            case let .feature1(state):
              return ._$id(for: state)._$tag(0)
            }
          }

          mutating func _$willModify() {
            switch self {
            case var .feature1(state):
              ComposableArchitecture._$willModify(&state)
              self = .feature1(state: state)
            }
          }
        }
        """
      }
    }

    func testObservableState_Enum_AccessControl() {
      assertMacro {
        """
        @ObservableState
        public enum Path {
          case feature1(Feature1.State)
          case feature2(Feature2.State)
        }
        """
      } expansion: {
        """
        public enum Path {
          case feature1(Feature1.State)
          case feature2(Feature2.State)

          public var _$id: ComposableArchitecture.ObservableStateID {
            switch self {
            case let .feature1(state):
              return ._$id(for: state)._$tag(0)
            case let .feature2(state):
              return ._$id(for: state)._$tag(1)
            }
          }

          public mutating func _$willModify() {
            switch self {
            case var .feature1(state):
              ComposableArchitecture._$willModify(&state)
              self = .feature1(state)
            case var .feature2(state):
              ComposableArchitecture._$willModify(&state)
              self = .feature2(state)
            }
          }
        }
        """
      }
    }

    func testObservableState_Enum_NonObservableCase() {
      assertMacro {
        """
        @ObservableState
        public enum Path {
          case foo(Int)
        }
        """
      } expansion: {
        """
        public enum Path {
          case foo(Int)

          public var _$id: ComposableArchitecture.ObservableStateID {
            switch self {
            case let .foo(state):
              return ._$id(for: state)._$tag(0)
            }
          }

          public mutating func _$willModify() {
            switch self {
            case var .foo(state):
              ComposableArchitecture._$willModify(&state)
              self = .foo(state)
            }
          }
        }
        """
      }
    }

    func testObservableState_Enum_MultipleAssociatedValues() {
      assertMacro {
        """
        @ObservableState
        public enum Path {
          case foo(Int, String)
        }
        """
      } expansion: {
        """
        public enum Path {
          case foo(Int, String)

          public var _$id: ComposableArchitecture.ObservableStateID {
            switch self {
            case .foo:
              return ._$inert._$tag(0)
            }
          }

          public mutating func _$willModify() {
            switch self {
            case .foo:
              break
            }
          }
        }
        """
      }
    }

    func testObservableState_Class() {
      assertMacro {
        """
        @ObservableState
        public class Model {
        }
        """
      } diagnostics: {
        """
        @ObservableState
        ┬───────────────
        ╰─ 🛑 '@ObservableState' cannot be applied to class type 'Model'
        public class Model {
        }
        """
      }
    }

    func testObservableState_Actor() {
      assertMacro {
        """
        @ObservableState
        public actor Model {
        }
        """
      } diagnostics: {
        """
        @ObservableState
        ┬───────────────
        ╰─ 🛑 '@ObservableState' cannot be applied to actor type 'Model'
        public actor Model {
        }
        """
      }
    }
  }
#endif
