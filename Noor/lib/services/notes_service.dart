import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class NotesService {
  static const String _notesKey = 'saved_notes';
  static const String _notesFolder = 'notes_images';

  /// Get all saved notes
  Future<List<Note>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      
      if (notesJson != null) {
        final notesList = jsonDecode(notesJson) as List;
        return notesList
            .map((noteData) => Note.fromJson(noteData))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Most recent first
      }
      
      return [];
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  /// Save a new note
  Future<bool> saveNote(Note note) async {
    try {
      final notes = await getAllNotes();
      
      // Check if note with same ID exists and update it
      final existingIndex = notes.indexWhere((n) => n.id == note.id);
      if (existingIndex != -1) {
        notes[existingIndex] = note;
      } else {
        notes.add(note);
      }
      
      return await _saveNotesToStorage(notes);
    } catch (e) {
      print('Error saving note: $e');
      return false;
    }
  }

  /// Update an existing note
  Future<bool> updateNote(Note updatedNote) async {
    try {
      final notes = await getAllNotes();
      final index = notes.indexWhere((n) => n.id == updatedNote.id);
      
      if (index != -1) {
        notes[index] = updatedNote.copyWith(updatedAt: DateTime.now());
        return await _saveNotesToStorage(notes);
      }
      
      return false;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      final notes = await getAllNotes();
      final noteToDelete = notes.firstWhere(
        (n) => n.id == noteId,
        orElse: () => throw Exception('Note not found'),
      );
      
      // Delete the associated image file
      if (noteToDelete.imagePath.isNotEmpty) {
        await _deleteImageFile(noteToDelete.imagePath);
      }
      
      // Remove from list
      notes.removeWhere((n) => n.id == noteId);
      
      return await _saveNotesToStorage(notes);
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  /// Search notes by content, title, or tags
  Future<List<Note>> searchNotes(String searchTerm) async {
    try {
      final allNotes = await getAllNotes();
      
      if (searchTerm.isEmpty) {
        return allNotes;
      }
      
      return allNotes
          .where((note) => note.containsSearchTerm(searchTerm))
          .toList();
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  /// Get notes by tag
  Future<List<Note>> getNotesByTag(String tag) async {
    try {
      final allNotes = await getAllNotes();
      return allNotes
          .where((note) => note.tags.contains(tag))
          .toList();
    } catch (e) {
      print('Error getting notes by tag: $e');
      return [];
    }
  }

  /// Get all unique tags from all notes
  Future<List<String>> getAllTags() async {
    try {
      final allNotes = await getAllNotes();
      final tags = <String>{};
      
      for (final note in allNotes) {
        tags.addAll(note.tags);
      }
      
      return tags.toList()..sort();
    } catch (e) {
      print('Error getting tags: $e');
      return [];
    }
  }

  /// Save image file and return the path
  Future<String> saveImageFile(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${appDir.path}/$_notesFolder');
      
      // Create notes directory if it doesn't exist
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = sourcePath.split('.').last;
      final fileName = 'note_$timestamp.$extension';
      final destinationPath = '${notesDir.path}/$fileName';
      
      // Copy file to app directory
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      
      return destinationPath;
    } catch (e) {
      print('Error saving image file: $e');
      return '';
    }
  }

  /// Get notes statistics
  Future<Map<String, dynamic>> getNotesStatistics() async {
    try {
      final notes = await getAllNotes();
      final tags = await getAllTags();
      
      // Calculate statistics
      final totalNotes = notes.length;
      final totalTags = tags.length;
      final recentNotes = notes
          .where((note) => DateTime.now().difference(note.createdAt).inDays <= 7)
          .length;
      
      // Most used tags
      final tagCounts = <String, int>{};
      for (final note in notes) {
        for (final tag in note.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      
      final mostUsedTags = tagCounts.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'totalNotes': totalNotes,
        'totalTags': totalTags,
        'recentNotes': recentNotes,
        'mostUsedTags': mostUsedTags.take(5).toList(),
        'oldestNote': notes.isNotEmpty 
            ? notes.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b).createdAt
            : null,
        'newestNote': notes.isNotEmpty 
            ? notes.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b).createdAt
            : null,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalNotes': 0,
        'totalTags': 0,
        'recentNotes': 0,
        'mostUsedTags': <MapEntry<String, int>>[],
        'oldestNote': null,
        'newestNote': null,
      };
    }
  }

  /// Private helper methods
  Future<bool> _saveNotesToStorage(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = jsonEncode(notes.map((note) => note.toJson()).toList());
      return await prefs.setString(_notesKey, notesJson);
    } catch (e) {
      print('Error saving notes to storage: $e');
      return false;
    }
  }

  Future<void> _deleteImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image file: $e');
    }
  }

  /// Export notes as text (for backup or sharing)
  Future<String> exportNotesAsText() async {
    try {
      final notes = await getAllNotes();
      final buffer = StringBuffer();
      
      buffer.writeln('📝 My Notes Export');
      buffer.writeln('Generated on: ${DateTime.now().toString()}');
      buffer.writeln('Total Notes: ${notes.length}');
      buffer.writeln('${'=' * 50}');
      buffer.writeln();
      
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        buffer.writeln('Note ${i + 1}: ${note.title}');
        buffer.writeln('Created: ${note.createdAt.toString()}');
        buffer.writeln('Tags: ${note.tags.join(', ')}');
        buffer.writeln('Content:');
        buffer.writeln(note.content);
        buffer.writeln('-' * 30);
        buffer.writeln();
      }
      
      return buffer.toString();
    } catch (e) {
      print('Error exporting notes: $e');
      return 'Error exporting notes: $e';
    }
  }
}