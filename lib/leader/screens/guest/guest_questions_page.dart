// guest_questions_page.dart
// Google Forms-style question builder for private event guest questionnaires.
// Leaders can create, edit, delete, and reorder questions.
// Supported types: Short Answer, Paragraph, Multiple Choice, Checkbox, Dropdown.
//
// TODO: Check if current user has guest management permission (for future member access)

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../leader_dashboard.dart';

class GuestQuestionsPage extends StatefulWidget {
  final String eventCode;

  const GuestQuestionsPage({Key? key, required this.eventCode}) : super(key: key);

  @override
  _GuestQuestionsPageState createState() => _GuestQuestionsPageState();
}

class _GuestQuestionsPageState extends State<GuestQuestionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Supported question types (Google Forms style)
  static const List<String> questionTypes = [
    'short_answer',
    'paragraph',
    'multiple_choice',
    'checkbox',
    'dropdown',
  ];

  // Human-readable labels for question types
  static const Map<String, String> typeLabels = {
    'short_answer': 'Short Answer',
    'paragraph': 'Paragraph',
    'multiple_choice': 'Multiple Choice',
    'checkbox': 'Checkboxes',
    'dropdown': 'Dropdown',
  };

  // Icons for each question type
  static const Map<String, IconData> typeIcons = {
    'short_answer': Icons.short_text,
    'paragraph': Icons.notes,
    'multiple_choice': Icons.radio_button_checked,
    'checkbox': Icons.check_box,
    'dropdown': Icons.arrow_drop_down_circle,
  };

  /// Show dialog to add or edit a question
  void _showQuestionDialog({DocumentSnapshot? existingDoc}) {
    final isEditing = existingDoc != null;
    Map<String, dynamic>? existingData;
    if (isEditing) {
      existingData = existingDoc!.data() as Map<String, dynamic>;
    }

    final questionController = TextEditingController(
      text: isEditing ? existingData!['question'] ?? '' : '',
    );
    String selectedType = isEditing ? existingData!['type'] ?? 'short_answer' : 'short_answer';
    bool isRequired = isEditing ? existingData!['isRequired'] ?? false : false;
    List<String> options = isEditing && existingData!['options'] != null
        ? List<String>.from(existingData!['options'])
        : [''];

    // Whether the selected type needs options
    bool needsOptions(String type) {
      return type == 'multiple_choice' || type == 'checkbox' || type == 'dropdown';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Question' : 'Add Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(
                        labelText: 'Question',
                        hintText: 'Enter your question...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),

                    // Question type dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Question Type',
                        border: OutlineInputBorder(),
                      ),
                      items: questionTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(typeIcons[type], size: 20),
                              SizedBox(width: 8),
                              Text(typeLabels[type]!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                          // Reset options when switching to a type that needs them
                          if (needsOptions(selectedType) && options.isEmpty) {
                            options = [''];
                          }
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Options list (only for MCQ, Checkbox, Dropdown)
                    if (needsOptions(selectedType)) ...[
                      Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...List.generate(options.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              // Option type indicator icon
                              Icon(
                                selectedType == 'multiple_choice'
                                    ? Icons.radio_button_unchecked
                                    : selectedType == 'checkbox'
                                        ? Icons.check_box_outline_blank
                                        : Icons.arrow_drop_down,
                                size: 20,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Option ${index + 1}',
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(text: options[index]),
                                  onChanged: (val) => options[index] = val,
                                ),
                              ),
                              // Delete option button
                              if (options.length > 1)
                                IconButton(
                                  icon: Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setDialogState(() => options.removeAt(index));
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      // Add option button
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() => options.add(''));
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add Option'),
                      ),
                    ],
                    SizedBox(height: 8),

                    // Required toggle
                    SwitchListTile(
                      title: Text('Required'),
                      subtitle: Text(isRequired ? 'Guest must answer' : 'Optional question'),
                      value: isRequired,
                      onChanged: (val) {
                        setDialogState(() => isRequired = val);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String questionText = questionController.text.trim();
                    if (questionText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Question text cannot be empty')),
                      );
                      return;
                    }

                    // Clean up empty options
                    List<String> cleanedOptions = options
                        .map((o) => o.trim())
                        .where((o) => o.isNotEmpty)
                        .toList();

                    if (needsOptions(selectedType) && cleanedOptions.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please add at least 2 options')),
                      );
                      return;
                    }

                    Map<String, dynamic> questionData = {
                      'question': questionText,
                      'type': selectedType,
                      'isRequired': isRequired,
                      'options': needsOptions(selectedType) ? cleanedOptions : [],
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (isEditing) {
                        // Preserve original order
                        questionData['order'] = existingData!['order'] ?? 0;
                        await _firestore
                            .collection('events')
                            .doc(widget.eventCode)
                            .collection('guestQuestions')
                            .doc(existingDoc!.id)
                            .update(questionData);
                      } else {
                        // Get current question count for ordering
                        QuerySnapshot existing = await _firestore
                            .collection('events')
                            .doc(widget.eventCode)
                            .collection('guestQuestions')
                            .get();
                        questionData['order'] = existing.docs.length;

                        await _firestore
                            .collection('events')
                            .doc(widget.eventCode)
                            .collection('guestQuestions')
                            .add(questionData);
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Question updated!' : 'Question added!')),
                      );
                    } catch (e) {
                      print('Error saving question: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save question')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Delete a question with confirmation
  void _deleteQuestion(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Question'),
        content: Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore
                  .collection('events')
                  .doc(widget.eventCode)
                  .collection('guestQuestions')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Question deleted')),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guest Questions'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            tooltip: 'Add Question',
            onPressed: () => _showQuestionDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('events')
            .doc(widget.eventCode)
            .collection('guestQuestions')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add questions for guests',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showQuestionDialog(),
                    icon: Icon(Icons.add),
                    label: Text('Add First Question'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'short_answer';
              final isRequired = data['isRequired'] ?? false;
              final options = data['options'] != null ? List<String>.from(data['options']) : <String>[];

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isRequired
                      ? BorderSide(color: Colors.red.shade200, width: 1)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: question number + type badge + actions
                      Row(
                        children: [
                          // Question number
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Type badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcons[type], size: 14, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  typeLabels[type] ?? type,
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                          if (isRequired) ...[
                            SizedBox(width: 6),
                            Text('*', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                          Spacer(),
                          // Edit button
                          IconButton(
                            icon: Icon(Icons.edit, size: 20),
                            onPressed: () => _showQuestionDialog(existingDoc: doc),
                          ),
                          // Delete button
                          IconButton(
                            icon: Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteQuestion(doc.id),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Question text
                      Text(
                        data['question'] ?? '',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),

                      // Show options preview for MCQ/Checkbox/Dropdown
                      if (options.isNotEmpty) ...[
                        SizedBox(height: 8),
                        ...options.map((opt) => Padding(
                              padding: EdgeInsets.only(left: 8, top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    type == 'multiple_choice'
                                        ? Icons.radio_button_unchecked
                                        : type == 'checkbox'
                                            ? Icons.check_box_outline_blank
                                            : Icons.arrow_drop_down,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(opt, style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                            )),
                      ],

                      // Show answer placeholder for text types
                      if (type == 'short_answer')
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Short answer text',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      if (type == 'paragraph')
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Long answer text...',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // FAB to go back to dashboard
      floatingActionButton: customFloatingActionButton(onPressed: () {
        Navigator.pop(context);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
