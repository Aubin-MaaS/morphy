import 'package:zikzak_morphy_annotation/morphy_annotation.dart';
import 'package:test/test.dart';

part 'regular_enum_test.g.dart';
part 'regular_enum_test.morphy.dart';

// Regular Dart enum (should NOT get patch methods)
enum Priority { low, medium, high, urgent }

enum Status { pending, inProgress, completed, cancelled }

@Morphy(generateJson: true)
abstract class $Task {
  String get title;
  String get description;
  Priority get priority; // Regular enum field
  Status get status; // Regular enum field
  DateTime get createdAt;
}

@Morphy(generateJson: true)
abstract class $Project {
  String get name;
  List<$Task> get tasks;
  Map<String, Priority> get defaultPriorities; // Map with regular enum values
}

main() {
  group('Regular Dart enum handling', () {
    late Task testTask;
    late Project testProject;

    setUp(() {
      testTask = Task(
        title: 'Test Task',
        description: 'A test task',
        priority: Priority.medium,
        status: Status.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      testProject = Project(
        name: 'Test Project',
        tasks: [testTask],
        defaultPriorities: {'normal': Priority.medium, 'urgent': Priority.high},
      );
    });

    test('should NOT generate withPriorityPatch for regular enum fields', () {
      final taskPatch = TaskPatch.create();

      // Regular with methods should exist
      expect(() => taskPatch.withPriority(Priority.high), returnsNormally);
      expect(() => taskPatch.withStatus(Status.completed), returnsNormally);

      // But patch methods should NOT exist for regular enums
      // These would cause compilation errors if they existed:
      // taskPatch.withPriorityPatch(...)  // Should not exist
      // taskPatch.withStatusPatch(...)    // Should not exist

      // Verify the basic with methods work correctly
      taskPatch
        ..withPriority(Priority.high)
        ..withStatus(Status.completed);

      final patchMap = taskPatch.toPatch();
      expect(patchMap[Task$.priority], equals(Priority.high));
      expect(patchMap[Task$.status], equals(Status.completed));
    });

    test('should handle regular enum updates correctly', () {
      final taskPatch = TaskPatch.create()
        ..withTitle('Updated Task')
        ..withPriority(Priority.urgent)
        ..withStatus(Status.inProgress);

      final updatedTask = taskPatch.applyTo(testTask);

      expect(updatedTask.title, equals('Updated Task'));
      expect(updatedTask.priority, equals(Priority.urgent));
      expect(updatedTask.status, equals(Status.inProgress));
      expect(updatedTask.description, equals('A test task')); // unchanged
      expect(updatedTask.createdAt, equals(DateTime(2024, 1, 1))); // unchanged
    });

    test(
      'should NOT generate patch methods for Map with regular enum values',
      () {
        final projectPatch = ProjectPatch.create();

        // Regular with methods should exist
        expect(() => projectPatch.withName('New Project'), returnsNormally);
        expect(
          () => projectPatch.withDefaultPriorities({'key': Priority.low}),
          returnsNormally,
        );

        // But update methods for enum values should NOT exist
        // This would cause compilation error if it existed:
        // projectPatch.updateDefaultPrioritiesValue('key', (patch) => ...)
      },
    );

    test('should handle Map updates with regular enums correctly', () {
      final projectPatch = ProjectPatch.create()
        ..withName('Updated Project')
        ..withDefaultPriorities({'low': Priority.low, 'high': Priority.urgent});

      final updatedProject = projectPatch.applyTo(testProject);

      expect(updatedProject.name, equals('Updated Project'));
      expect(updatedProject.defaultPriorities['low'], equals(Priority.low));
      expect(updatedProject.defaultPriorities['high'], equals(Priority.urgent));
      expect(updatedProject.defaultPriorities.length, equals(2));
    });

    test('should update List of objects containing regular enums', () {
      final projectPatch = ProjectPatch.create()
        ..updateTasksAt(
          0,
          (taskPatch) => taskPatch
            ..withTitle('Updated Task in List')
            ..withPriority(Priority.high),
        );

      final updatedProject = projectPatch.applyTo(testProject);

      expect(updatedProject.tasks[0].title, equals('Updated Task in List'));
      expect(updatedProject.tasks[0].priority, equals(Priority.high));
      expect(
        updatedProject.tasks[0].status,
        equals(Status.pending),
      ); // unchanged
    });

    test('should preserve regular enum values in partial updates', () {
      final taskPatch = TaskPatch.create()
        ..withTitle('Partial Update'); // Only update title

      final updatedTask = taskPatch.applyTo(testTask);

      expect(updatedTask.title, equals('Partial Update'));
      expect(updatedTask.priority, equals(Priority.medium)); // preserved
      expect(updatedTask.status, equals(Status.pending)); // preserved
      expect(updatedTask.description, equals('A test task')); // preserved
    });

    test('should handle JSON serialization with regular enums', () {
      final task = Task(
        title: 'JSON Test',
        description: 'Test JSON',
        priority: Priority.high,
        status: Status.completed,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = task.toJson();
      expect(json['priority'], equals('high')); // Enum serialized as string
      expect(json['status'], equals('completed'));

      final fromJson = Task.fromJson(json);
      expect(fromJson.priority, equals(Priority.high));
      expect(fromJson.status, equals(Status.completed));
      expect(fromJson, equals(task));
    });

    group('compareTo functionality with regular enums', () {
      test('should generate compareToTask method for Task', () {
        final task1 = Task(
          title: 'Task One',
          description: 'First task',
          priority: Priority.medium,
          status: Status.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final task2 = Task(
          title: 'Task Two',
          description: 'Second task',
          priority: Priority.high,
          status: Status.completed,
          createdAt: DateTime(2024, 1, 2),
        );

        final diff = task1.compareToTask(task2);

        // Should contain all different fields
        expect(diff.keys, contains('title'));
        expect(diff.keys, contains('description'));
        expect(diff.keys, contains('priority'));
        expect(diff.keys, contains('status'));
        expect(diff.keys, contains('createdAt'));

        // Check that functions return the correct new values
        expect(diff['title']!(), equals('Task Two'));
        expect(diff['description']!(), equals('Second task'));
        expect(diff['priority']!(), equals(Priority.high));
        expect(diff['status']!(), equals(Status.completed));
        expect(diff['createdAt']!(), equals(DateTime(2024, 1, 2)));
      });

      test('should only show differences in compareToTask', () {
        final task1 = Task(
          title: 'Same Title',
          description: 'Different description',
          priority: Priority.medium,
          status: Status.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final task2 = Task(
          title: 'Same Title', // Same
          description: 'Updated description', // Different
          priority: Priority.medium, // Same
          status: Status.completed, // Different
          createdAt: DateTime(2024, 1, 1), // Same
        );

        final diff = task1.compareToTask(task2);

        // Should only contain different fields
        expect(diff.keys, hasLength(2));
        expect(diff.keys, contains('description'));
        expect(diff.keys, contains('status'));
        expect(diff.keys, isNot(contains('title')));
        expect(diff.keys, isNot(contains('priority')));
        expect(diff.keys, isNot(contains('createdAt')));

        expect(diff['description']!(), equals('Updated description'));
        expect(diff['status']!(), equals(Status.completed));
      });

      test('should handle identical objects in compareToTask', () {
        final task1 = Task(
          title: 'Identical Task',
          description: 'Same description',
          priority: Priority.low,
          status: Status.inProgress,
          createdAt: DateTime(2024, 1, 1),
        );

        final task2 = Task(
          title: 'Identical Task',
          description: 'Same description',
          priority: Priority.low,
          status: Status.inProgress,
          createdAt: DateTime(2024, 1, 1),
        );

        final diff = task1.compareToTask(task2);

        // Should be empty for identical objects
        expect(diff, isEmpty);
      });

      test('should generate compareToProject method for nested objects', () {
        final task1 = Task(
          title: 'Task 1',
          description: 'First',
          priority: Priority.low,
          status: Status.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final task2 = Task(
          title: 'Task 2',
          description: 'Second',
          priority: Priority.high,
          status: Status.completed,
          createdAt: DateTime(2024, 1, 2),
        );

        final project1 = Project(
          name: 'Project Alpha',
          tasks: [task1],
          defaultPriorities: {'normal': Priority.medium},
        );

        final project2 = Project(
          name: 'Project Beta',
          tasks: [task2],
          defaultPriorities: {
            'normal': Priority.high,
            'urgent': Priority.urgent,
          },
        );

        final diff = project1.compareToProject(project2);

        // Should show all different fields
        expect(diff.keys, contains('name'));
        expect(diff.keys, contains('tasks'));
        expect(diff.keys, contains('defaultPriorities'));

        expect(diff['name']!(), equals('Project Beta'));
        expect(diff['tasks']!(), equals([task2]));
        expect(
          diff['defaultPriorities']!(),
          equals({'normal': Priority.high, 'urgent': Priority.urgent}),
        );
      });

      test('should handle enum comparisons correctly', () {
        final task1 = Task(
          title: 'Enum Test',
          description: 'Testing enums',
          priority: Priority.low,
          status: Status.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final task2 = Task(
          title: 'Enum Test',
          description: 'Testing enums',
          priority: Priority.urgent, // Different enum value
          status: Status.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final diff = task1.compareToTask(task2);

        expect(diff.keys, hasLength(1));
        expect(diff.keys, contains('priority'));
        expect(diff['priority']!(), equals(Priority.urgent));
      });

      test('should work with patch creation from compareTo', () {
        final originalTask = Task(
          title: 'Original',
          description: 'Original description',
          priority: Priority.medium,
          status: Status.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final targetTask = Task(
          title: 'Updated',
          description: 'Updated description',
          priority: Priority.high,
          status: Status.completed,
          createdAt: DateTime(2024, 1, 1), // Same
        );

        // Get the differences
        final diff = originalTask.compareToTask(targetTask);

        // Create a patch from the differences
        final patch = TaskPatch.create(diff);

        // Apply the patch
        final resultTask = patch.applyTo(originalTask);

        // Should match the target (except for unchanged fields)
        expect(resultTask.title, equals(targetTask.title));
        expect(resultTask.description, equals(targetTask.description));
        expect(resultTask.priority, equals(targetTask.priority));
        expect(resultTask.status, equals(targetTask.status));
        expect(resultTask.createdAt, equals(targetTask.createdAt));
        expect(resultTask, equals(targetTask));
      });

      test('should handle complex project comparison with enum maps', () {
        final project1 = Project(
          name: 'Complex Project',
          tasks: [],
          defaultPriorities: {'low': Priority.low, 'medium': Priority.medium},
        );

        final project2 = Project(
          name: 'Complex Project', // Same
          tasks: [], // Same
          defaultPriorities: {
            'low': Priority.medium, // Changed
            'medium': Priority.medium, // Same
            'high': Priority.urgent, // Added
          },
        );

        final diff = project1.compareToProject(project2);

        expect(diff.keys, hasLength(1));
        expect(diff.keys, contains('defaultPriorities'));

        final newPriorities =
            diff['defaultPriorities']!() as Map<String, Priority>;
        expect(newPriorities['low'], equals(Priority.medium));
        expect(newPriorities['medium'], equals(Priority.medium));
        expect(newPriorities['high'], equals(Priority.urgent));
      });
    });
  });
}
