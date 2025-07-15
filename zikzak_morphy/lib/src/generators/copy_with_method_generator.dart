import '../common/NameType.dart';
import 'method_generator_commons.dart';
import 'parameter_generator.dart';
import 'constructor_parameter_generator.dart';

/// Generates simple copyWith methods without patchInput parameters
class CopyWithMethodGenerator {
  /// Generate a simple copyWith method for an interface
  static String generateCopyWithMethod({
    required List<NameType> classFields,
    required List<NameType> interfaceFields,
    required String interfaceName,
    required String className,
    required bool isClassAbstract,
    List<NameType> interfaceGenerics = const [],
    List<NameType> classGenerics = const [],
    List<String> knownClasses = const [],
    bool nonSealed = false,
    bool hidePublicConstructor = false,
  }) {
    // For nonSealed classes, allow method generation even if interface name starts with $$
    // if it's the class's own interface (cleaned names match)
    if (NameCleaner.isAbstract(interfaceName)) {
      if (!nonSealed ||
          NameCleaner.clean(interfaceName) != NameCleaner.clean(className)) {
        return '';
      }
    }

    final cleanClassName = NameCleaner.clean(className);
    final cleanInterfaceName = NameCleaner.clean(interfaceName);
    // Use class generics for type parameters when class is generic
    final typeParams = classGenerics.isNotEmpty
        ? TypeResolver.generateTypeParams(
            classGenerics,
            isAbstractInterface: true,
          )
        : '';

    final parameters = ParameterGenerator.generateCopyWithParameters(
      interfaceFields,
      interfaceGenerics,
      isAbstractInterface: false,
      isInterfaceMethod: true,
    );

    final constructorParams =
        ConstructorParameterGenerator.generateCopyWithConstructorParams(
          classFields,
          interfaceFields,
        );

    final constructorName = MethodGeneratorCommons.getConstructorName(
      NameCleaner.clean(className),
      hidePublicConstructor,
    );

    return '''
      $cleanClassName$typeParams copyWith$cleanInterfaceName(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        return $constructorName(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate simple copyWith method for class fields
  static String generateClassCopyWithMethod({
    required List<NameType> classFields,
    required String className,
    required List<NameType> classGenerics,
    List<String> knownClasses = const [],
    bool hidePublicConstructor = false,
  }) {
    final cleanClassName = NameCleaner.clean(className);
    final typeParams = TypeResolver.generateTypeParams(
      classGenerics,
      isAbstractInterface: true,
    );

    final parameters = ParameterGenerator.generateCopyWithParameters(
      classFields,
      classGenerics,
      isAbstractInterface: false,
    );

    final constructorParams = _generateSimpleClassConstructorParams(
      classFields,
    );

    final constructorName = MethodGeneratorCommons.getConstructorName(
      cleanClassName,
      hidePublicConstructor,
    );

    return '''
      $cleanClassName$typeParams copyWith$cleanClassName(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        return $constructorName(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate constructor parameters for simple class copyWith
  static String _generateSimpleClassConstructorParams(
    List<NameType> classFields,
  ) {
    final constructorFields = classFields.map((f) {
      final name = MethodGeneratorCommons.getCleanFieldName(f.name);
      return '$name: $name ?? this.${f.name}';
    });

    return constructorFields.join(',\n          ');
  }

  /// Generate multiple copyWith methods for a class implementing multiple interfaces
  static String generateMultipleCopyWithMethods({
    required List<NameType> classFields,
    required Map<String, List<NameType>> interfaceFieldsMap,
    required Map<String, List<NameType>> interfaceGenericsMap,
    required String className,
    required bool isClassAbstract,
    List<NameType> classGenerics = const [],
    List<String> knownClasses = const [],
    bool nonSealed = false,
    bool hidePublicConstructor = false,
  }) {
    final methods = <String>[];

    // Generate copyWith for each interface
    interfaceFieldsMap.forEach((interfaceName, interfaceFields) {
      final interfaceGenerics = interfaceGenericsMap[interfaceName] ?? [];

      final method = generateCopyWithMethod(
        classFields: classFields,
        interfaceFields: interfaceFields,
        interfaceName: interfaceName,
        className: className,
        isClassAbstract: isClassAbstract,
        interfaceGenerics: interfaceGenerics,
        classGenerics: classGenerics,
        knownClasses: knownClasses,
        nonSealed: nonSealed,
        hidePublicConstructor: hidePublicConstructor,
      );

      if (method.isNotEmpty) {
        methods.add(method);
      }
    });

    return methods.join('\n\n');
  }

  /// Generate copyWith method with function parameters
  static String generateCopyWithFunctionMethod({
    required List<NameType> classFields,
    required List<NameType> interfaceFields,
    required String interfaceName,
    required String className,
    required List<NameType> interfaceGenerics,
    List<NameType> classGenerics = const [],
    List<String> knownClasses = const [],
    bool nonSealed = false,
    bool hidePublicConstructor = false,
  }) {
    // For nonSealed classes, allow method generation even if interface name starts with $$
    // if it's the class's own interface (cleaned names match)
    if (NameCleaner.isAbstract(interfaceName)) {
      if (!nonSealed ||
          NameCleaner.clean(interfaceName) != NameCleaner.clean(className)) {
        return '';
      }
    }

    final cleanClassName = NameCleaner.clean(className);
    final cleanInterfaceName = NameCleaner.clean(interfaceName);
    // Use class generics for type parameters when class is generic
    final typeParams = classGenerics.isNotEmpty
        ? TypeResolver.generateTypeParams(
            classGenerics,
            isAbstractInterface: true,
          )
        : '';

    final parameters = ParameterGenerator.generateFunctionParameters(
      interfaceFields,
      interfaceGenerics,
      isAbstractInterface: false,
      isInterfaceMethod: true,
    );

    final constructorParams = _generateFunctionBasedConstructorParams(
      classFields,
      interfaceFields,
    );

    final constructorName = MethodGeneratorCommons.getConstructorName(
      NameCleaner.clean(className),
      hidePublicConstructor,
    );

    return '''
      $cleanClassName$typeParams copyWith${cleanInterfaceName}Fn(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        return $constructorName(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate constructor parameters for function-based copyWith
  static String _generateFunctionBasedConstructorParams(
    List<NameType> targetClassFields,
    List<NameType> sourceInterfaceFields,
  ) {
    final sourceFieldNames = sourceInterfaceFields.map((f) => f.name).toSet();

    final constructorFields = targetClassFields.map((f) {
      final name = MethodGeneratorCommons.getCleanFieldName(f.name);
      final hasField = sourceFieldNames.contains(f.name);

      if (hasField) {
        // For interface fields, call function or use current value
        return '$name: $name != null ? $name() : this.${f.name}';
      } else {
        // For class-only fields, keep current value
        return '$name: this.${f.name}';
      }
    });

    return constructorFields.join(',\n          ');
  }
}
