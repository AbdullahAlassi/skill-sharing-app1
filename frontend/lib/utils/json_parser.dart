import 'dart:convert';

class JsonParser {
  /// Parses a non-standard JSON string where keys are not quoted
  static dynamic parseNonStandardJson(String input) {
    // First, try standard JSON parsing
    try {
      return jsonDecode(input);
    } catch (e) {
      // If standard parsing fails, try to fix the format
      try {
        // Add quotes around keys
        final fixedJson = _addQuotesToKeys(input);
        return jsonDecode(fixedJson);
      } catch (e) {
        print("Error parsing non-standard JSON: $e");
        print("Input was: $input");

        // As a fallback, try to extract data manually
        if (input.startsWith('[') && input.endsWith(']')) {
          // It's an array, try to extract objects
          return _extractArrayObjects(input);
        }

        // If all else fails, return an empty list or map
        return input.startsWith('[') ? [] : {};
      }
    }
  }

  /// Adds quotes around keys in a JSON-like string
  static String _addQuotesToKeys(String input) {
    // This is a simplified approach - a more robust solution would use a proper parser
    // Replace patterns like {key: value} with {"key": value}
    final result = input.replaceAllMapped(
      RegExp(r'([{,])\s*([a-zA-Z0-9_]+)\s*:'),
      (match) => '${match.group(1)}"${match.group(2)}":',
    );
    return result;
  }

  /// Extracts objects from an array-like string
  static List<Map<String, dynamic>> _extractArrayObjects(String input) {
    final List<Map<String, dynamic>> result = [];

    // Remove the outer brackets
    final content = input.substring(1, input.length - 1).trim();

    // Split by objects - this is a simplified approach
    final objectStrings = _splitByObjects(content);

    for (final objStr in objectStrings) {
      if (objStr.isNotEmpty) {
        try {
          // Try to parse each object
          final objMap = _extractObjectProperties(objStr);
          if (objMap.isNotEmpty) {
            result.add(objMap);
          }
        } catch (e) {
          print("Error extracting object: $e");
        }
      }
    }

    return result;
  }

  /// Splits a string by objects (handling nested objects)
  static List<String> _splitByObjects(String input) {
    final List<String> result = [];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '{') {
        if (depth == 0) {
          start = i;
        }
        depth++;
      } else if (input[i] == '}') {
        depth--;
        if (depth == 0) {
          result.add(input.substring(start, i + 1));
        }
      } else if (input[i] == ',' && depth == 0) {
        // Skip commas between objects
      }
    }

    return result;
  }

  /// Extracts properties from an object-like string
  static Map<String, dynamic> _extractObjectProperties(String input) {
    final Map<String, dynamic> result = {};

    // Remove the outer braces
    final content = input.substring(1, input.length - 1).trim();

    // Split by properties
    final props = _splitByProperties(content);

    for (final prop in props) {
      final parts = prop.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();

        // Add to result
        result[key] = _parseValue(value);
      }
    }

    return result;
  }

  /// Splits a string by properties (handling nested objects)
  static List<String> _splitByProperties(String input) {
    final List<String> result = [];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '{' || input[i] == '[') {
        depth++;
      } else if (input[i] == '}' || input[i] == ']') {
        depth--;
      } else if (input[i] == ',' && depth == 0) {
        result.add(input.substring(start, i).trim());
        start = i + 1;
      }
    }

    if (start < input.length) {
      result.add(input.substring(start).trim());
    }

    return result;
  }

  /// Parses a value from a string
  static dynamic _parseValue(String value) {
    value = value.trim();

    // Try to parse as number
    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
      return num.tryParse(value) ?? value;
    }

    // Try to parse as boolean
    if (value == 'true') return true;
    if (value == 'false') return false;

    // Try to parse as null
    if (value == 'null') return null;

    // Try to parse as array
    if (value.startsWith('[') && value.endsWith(']')) {
      final content = value.substring(1, value.length - 1).trim();
      if (content.isEmpty) return [];

      final items = _splitArrayItems(content);
      return items.map((item) => _parseValue(item)).toList();
    }

    // Try to parse as object
    if (value.startsWith('{') && value.endsWith('}')) {
      return _extractObjectProperties(value);
    }

    // Remove quotes if string
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    if (value.startsWith("'") && value.endsWith("'")) {
      return value.substring(1, value.length - 1);
    }

    // Return as is
    return value;
  }

  /// Splits array items (handling nested arrays and objects)
  static List<String> _splitArrayItems(String input) {
    final List<String> result = [];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '{' || input[i] == '[') {
        depth++;
      } else if (input[i] == '}' || input[i] == ']') {
        depth--;
      } else if (input[i] == ',' && depth == 0) {
        result.add(input.substring(start, i).trim());
        start = i + 1;
      }
    }

    if (start < input.length) {
      result.add(input.substring(start).trim());
    }

    return result;
  }
}
