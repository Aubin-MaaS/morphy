import '../common/NameType.dart';
import 'method_generator_commons.dart';
import 'parameter_generator.dart';
import 'constructor_parameter_generator.dart';

/// Generates changeTo methods that create new instances with specified changes
class ChangeToMethodGenerator {
  /// Generate a changeTo method for an interface
  static String generateChangeToMethod({
    required List<NameType> classFields,
    required List<NameType> interfaceFields,
    required String interfaceName,
    required String className,
    required bool isClassAbstract,
    List<NameType> interfaceGenerics = const [],
    List<String> knownClasses = const [],
    bool isInterfaceSealed = false,
    List<NameType> classGenerics = const [],
    bool nonSealed = false,
    bool hidePublicConstructor = false,
    bool interfaceHidePublicConstructor = false,
  }) {
    // Never generate changeTo methods for sealed interfaces (starting with $$)
    // These cannot be instantiated directly
    if (NameCleaner.isAbstract(interfaceName)) {
      return '';
    }

    // Never generate changeTo methods for explicitly sealed interfaces
    if (isInterfaceSealed) {
      return '';
    }

    // Never generate changeTo methods for interfaces with hidePublicConstructor: true
    // because they don't have a public constructor to call
    if (interfaceHidePublicConstructor) {
      return '';
    }

    final cleanInterfaceName = NameCleaner.clean(interfaceName);
    // Determine if this is a changeTo method for an explicitSubType (when interface != class)
    final isExplicitSubType =
        NameCleaner.clean(interfaceName) != NameCleaner.clean(className);

    // For explicitSubTypes with generics, make the method generic
    final typeParams = isExplicitSubType && interfaceGenerics.isNotEmpty
        ? TypeResolver.generateTypeParams(
            interfaceGenerics,
            isAbstractInterface: true,
          )
        : '';

    final parameters = ParameterGenerator.generateChangeToParameters(
      interfaceFields,
      classFields,
      interfaceGenerics,
      isAbstractInterface: false,
      isInterfaceMethod: true,
    );

    final patchAssignments = ParameterGenerator.generatePatchAssignments(
      interfaceFields,
      classFields,
      isInterfaceMethod: true,
    );

    final constructorParams =
        ConstructorParameterGenerator.generateChangeToConstructorParams(
          interfaceFields,
          classFields,
          cleanInterfaceName,
          interfaceGenerics,
          knownClasses,
        );

    // Skip generation if no meaningful parameters
    if (parameters.trim().isEmpty && constructorParams.trim().isEmpty) {
      return '';
    }

    return '''
      $cleanInterfaceName$typeParams changeTo$cleanInterfaceName$typeParams(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        final _patcher = ${cleanInterfaceName}Patch();
        $patchAssignments
        final _patchMap = _patcher.toPatch();
        return ${MethodGeneratorCommons.getConstructorName(cleanInterfaceName, hidePublicConstructor)}(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate changeTo method for class fields
  static String generateClassChangeToMethod({
    required List<NameType> classFields,
    required String className,
    required List<NameType> classGenerics,
    List<String> knownClasses = const [],
    bool hidePublicConstructor = false,
  }) {
    final cleanClassName = NameCleaner.clean(className);
    final typeParams = TypeResolver.generateTypeParams(classGenerics);

    final parameters = ParameterGenerator.generateCopyWithParameters(
      classFields,
      classGenerics,
      isAbstractInterface: false,
    );

    final patchAssignments = ParameterGenerator.generatePatchAssignments(
      classFields,
      [],
    );

    final constructorParams = _generateSimpleClassChangeToConstructorParams(
      classFields,
      cleanClassName,
    );

    return '''
      $cleanClassName changeTo$cleanClassName(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        final _patcher = ${cleanClassName}Patch();
        $patchAssignments
        final _patchMap = _patcher.toPatch();
        return ${MethodGeneratorCommons.getConstructorName(cleanClassName, hidePublicConstructor)}(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate constructor parameters for simple class changeTo
  static String _generateSimpleClassChangeToConstructorParams(
    List<NameType> classFields,
    String className,
  ) {
    final constructorFields = classFields.map((f) {
      final name = MethodGeneratorCommons.getCleanFieldName(f.name);
      return '$name: _patchMap[$className\$.$name]';
    });

    return constructorFields.join(',\n          ');
  }

  /// Generate multiple changeTo methods for a class implementing multiple interfaces
  static String generateMultipleChangeToMethods({
    required List<NameType> classFields,
    required Map<String, List<NameType>> interfaceFieldsMap,
    required Map<String, List<NameType>> interfaceGenericsMap,
    required String className,
    required bool isClassAbstract,
    Map<String, bool> interfaceSealedMap = const {},
    List<String> knownClasses = const [],
    List<NameType> classGenerics = const [],
    bool nonSealed = false,
    bool hidePublicConstructor = false,
    Map<String, bool> interfaceHidePublicConstructorMap = const {},
  }) {
    final methods = <String>[];

    // Generate changeTo for each interface
    interfaceFieldsMap.forEach((interfaceName, interfaceFields) {
      final interfaceGenerics = interfaceGenericsMap[interfaceName] ?? [];
      final isInterfaceSealed = interfaceSealedMap[interfaceName] ?? false;
      final interfaceHidePublicConstructor =
          interfaceHidePublicConstructorMap[interfaceName] ?? false;

      final method = generateChangeToMethod(
        classFields: classFields,
        interfaceFields: interfaceFields,
        interfaceName: interfaceName,
        className: className,
        isClassAbstract: isClassAbstract,
        interfaceGenerics: interfaceGenerics,
        knownClasses: knownClasses,
        isInterfaceSealed: isInterfaceSealed,
        classGenerics: classGenerics,
        nonSealed: nonSealed,
        hidePublicConstructor: hidePublicConstructor,
        interfaceHidePublicConstructor: interfaceHidePublicConstructor,
      );

      if (method.isNotEmpty) {
        methods.add(method);
      }
    });

    return methods.join('\n\n');
  }

  /// Generate changeTo method with function-based parameters
  static String generateChangeToFunctionMethod({
    required List<NameType> classFields,
    required List<NameType> interfaceFields,
    required String interfaceName,
    required String className,
    required List<NameType> interfaceGenerics,
    List<String> knownClasses = const [],
    bool isInterfaceSealed = false,
    List<NameType> classGenerics = const [],
    bool nonSealed = false,
    bool hidePublicConstructor = false,
    bool interfaceHidePublicConstructor = false,
  }) {
    // Never generate changeTo methods for sealed interfaces (starting with $$)
    if (NameCleaner.isAbstract(interfaceName)) {
      return '';
    }

    // Never generate changeTo methods for explicitly sealed interfaces
    if (isInterfaceSealed) {
      return '';
    }

    // Never generate changeTo methods for interfaces with hidePublicConstructor: true
    if (interfaceHidePublicConstructor) {
      return '';
    }

    final cleanInterfaceName = NameCleaner.clean(interfaceName);
    final typeParams = TypeResolver.generateTypeParams(interfaceGenerics);

    final parameters = ParameterGenerator.generateFunctionParameters(
      interfaceFields,
      interfaceGenerics,
      isAbstractInterface: false,
    );

    final patchAssignments =
        ParameterGenerator.generateFunctionPatchAssignments(interfaceFields);

    final constructorParams =
        ConstructorParameterGenerator.generateChangeToConstructorParams(
          classFields,
          interfaceFields,
          cleanInterfaceName,
          interfaceGenerics,
          knownClasses,
        );

    // Skip generation if no meaningful parameters
    if (parameters.trim().isEmpty && constructorParams.trim().isEmpty) {
      return '';
    }

    return '''
      $cleanInterfaceName changeTo${cleanInterfaceName}Fn(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        final _patcher = ${cleanInterfaceName}Patch();
        $patchAssignments
        final _patchMap = _patcher.toPatch();
        return ${MethodGeneratorCommons.getConstructorName(cleanInterfaceName, hidePublicConstructor)}(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate changeTo method that preserves some fields from the current instance
  static String generatePartialChangeToMethod({
    required List<NameType> classFields,
    required List<NameType> interfaceFields,
    required List<NameType> preserveFields,
    required String interfaceName,
    required String className,
    required List<NameType> interfaceGenerics,
    List<String> knownClasses = const [],
    bool isInterfaceSealed = false,
    bool hidePublicConstructor = false,
    bool interfaceHidePublicConstructor = false,
  }) {
    // Never generate changeTo methods for sealed/abstract interfaces
    if (NameCleaner.isAbstract(interfaceName) || isInterfaceSealed) return '';

    // Never generate changeTo methods for interfaces with hidePublicConstructor: true
    if (interfaceHidePublicConstructor) return '';

    final cleanInterfaceName = NameCleaner.clean(interfaceName);
    final typeParams = TypeResolver.generateTypeParams(interfaceGenerics);

    // Only generate parameters for fields that are NOT preserved
    final preserveFieldNames = preserveFields.map((f) => f.name).toSet();
    final changeableFields = interfaceFields
        .where((f) => !preserveFieldNames.contains(f.name))
        .toList();

    final parameters = ParameterGenerator.generateChangeToParameters(
      changeableFields,
      classFields,
      interfaceGenerics,
      isAbstractInterface: false,
    );

    final patchAssignments = ParameterGenerator.generatePatchAssignments(
      changeableFields,
      classFields,
    );

    final constructorParams = _generatePartialChangeToConstructorParams(
      interfaceFields,
      classFields,
      preserveFields,
      cleanInterfaceName,
      interfaceGenerics,
      knownClasses,
    );

    return '''
      $cleanInterfaceName partialChangeTo$cleanInterfaceName(${parameters.isNotEmpty ? '{\n        $parameters\n      }' : ''}) {
        final _patcher = ${cleanInterfaceName}Patch();
        $patchAssignments
        final _patchMap = _patcher.toPatch();
        return ${MethodGeneratorCommons.getConstructorName(cleanInterfaceName, hidePublicConstructor)}(${constructorParams.isNotEmpty ? '\n          $constructorParams\n        ' : ''});
      }''';
  }

  /// Generate constructor parameters for partial changeTo
  static String _generatePartialChangeToConstructorParams(
    List<NameType> targetFields,
    List<NameType> classFields,
    List<NameType> preserveFields,
    String targetClassName,
    List<NameType> genericParams,
    List<String> knownClasses,
  ) {
    final preserveFieldNames = preserveFields.map((f) => f.name).toSet();
    final genericTypeNames = genericParams
        .map((g) => FieldTypeAnalyzer.cleanType(g.type))
        .toSet();

    final constructorFields = targetFields.map((f) {
      final name = MethodGeneratorCommons.getCleanFieldName(f.name);
      final isPreserved = preserveFieldNames.contains(f.name);

      if (isPreserved) {
        // Preserve current value for this field
        return '$name: this.${f.name}';
      } else {
        // Use patch value for changeable fields
        final baseType = FieldTypeAnalyzer.cleanType(
          f.type,
        ).replaceAll("?", "");
        final isEnum = f.isEnum;
        final isGenericType = TypeResolver.isGenericType(
          baseType,
          genericParams,
        );

        if (MethodGeneratorCommons.needsPatchHandling(
          baseType,
          isEnum,
          isGenericType,
          knownClasses,
        )) {
          final patchType = MethodGeneratorCommons.getPatchType(baseType);
          return '''$name: (_patchMap[$targetClassName\$.$name] is $patchType)
            ? (this.${f.name}?.copyWith$baseType(
                patchInput: _patchMap[$targetClassName\$.$name]
              ) ?? (() {
                try {
                  return $baseType.fromJson(
                    (_patchMap[$targetClassName\$.$name] as $patchType).toJson()
                  );
                } catch (e) {
                  throw StateError(
                    'Failed to create new $baseType instance from patch. '
                    'The field "$name" is null and the patch does not contain all required fields. '
                    'Error: \${e.toString()}'
                  );
                }
              })())
            : _patchMap[$targetClassName\$.$name] ?? this.${f.name}''';
        }
        return '$name: _patchMap[$targetClassName\$.$name]';
      }
    });

    return constructorFields.join(',\n          ');
  }
}
