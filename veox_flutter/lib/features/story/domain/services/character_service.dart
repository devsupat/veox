import 'package:flutter/foundation.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:uuid/uuid.dart';

class CharacterService {
  // Regex for capitalized words that might be names (Simple Heuristic)
  // Matches "Name" or "Name Surname" but avoids common sentence starters if possible.
  // In a real NLP system, we'd use a local BERT model, but for "Cost-Zero", regex + heuristics is best.
  static final RegExp _nameRegex = RegExp(r'\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)?\b');
  
  // Common English stopwords to filter out (The, A, An, When, Then...)
  static final Set<String> _stopWords = {
    'The', 'A', 'An', 'This', 'That', 'Then', 'When', 'Where', 'Why', 'How',
    'But', 'And', 'Or', 'If', 'So', 'Because', 'While', 'After', 'Before',
    'Once', 'Suddenly', 'Finally', 'Next', 'Later', 'Meanwhile', 'However',
    'Although', 'Even', 'Just', 'Only', 'Today', 'Yesterday', 'Tomorrow',
    'Here', 'There', 'It', 'He', 'She', 'They', 'We', 'You', 'I', 'His', 'Her', 'Their'
  };

  Future<List<CharacterModel>> extractCharacters(String text) async {
    // Run in compute isolate to avoid UI jank on long texts
    return await compute(_processText, text);
  }

  static List<CharacterModel> _processText(String text) {
    final Map<String, int> nameFrequency = {};
    
    // 1. Find matches
    final matches = _nameRegex.allMatches(text);
    
    for (final match in matches) {
      final word = match.group(0)!;
      // Filter out stop words and single letters
      if (!_stopWords.contains(word) && word.length > 2) {
        nameFrequency[word] = (nameFrequency[word] ?? 0) + 1;
      }
    }
    
    // 2. Filter by frequency (at least 2 occurrences usually means a character in a story)
    // Or just take top N. For now, let's take anything that looks like a name.
    final List<CharacterModel> characters = [];
    final uuid = Uuid();

    nameFrequency.forEach((name, count) {
      // Heuristic: If it appears > 1 time, likely a character.
      // If the story is very short, take everything.
      if (text.length < 500 || count > 1) {
        characters.add(CharacterModel()
          ..characterId = uuid.v4()
          ..name = name
          ..description = "Auto-detected character from story."
        );
      }
    });

    // Sort by frequency desc
    // We can't sort map easily, but the list is built.
    // Let's just return as is.
    return characters;
  }
}
