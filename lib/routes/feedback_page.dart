import 'dart:convert';

import 'package:app4training/data/feedback.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/check_now_button.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key, this.worksheetPage, this.langCode});

  final String? worksheetPage;
  final String? langCode;

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class FeedbackArguments {
  final String? worksheetPage;
  final String? langCode;

  FeedbackArguments({this.worksheetPage, this.langCode});
}

final List<String> feedbackOptions = ["Bug", "Translation", "Content"];

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  FeedbackType? _feedbackType;

  setFeedbackType(FeedbackType? type) {
    setState(() {
      _feedbackType = type;
      if (type != FeedbackType.feedback) {
        _responseNeeded = true;
      }
    });
  }

  bool? _responseNeeded;

  setResponseNeeded(bool? value) {
    setState(() {
      _responseNeeded = value;
    });
  }

  String? _selectedOption;
  setSelectedOption(String option) {
    setState(() {
      if (_selectedOption == option) {
        _selectedOption = null;
      } else {
        _selectedOption = option;
      }
    });
  }

  ResponseOption? _responseOption;
  bool _canSend = false;
  final TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();

  void _sendFeedback() async {
    Map<String, Object?>? body = await buildFeedbackJson();

    if (body != null) {
      await http
          .post(
              Uri.parse(
                  "https://maker.ifttt.com/trigger/FeedbackSend/json/with/key/c2fuEU64Du8HulwwOxqk5k"),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(body))
          .then((response) {
        if (response.statusCode == 200) {
          SnackBar snackBar = SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Sent message"),
            margin: EdgeInsets.all(16),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pop(context);
        } else {
          SnackBar snackBar = SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Problem sending message (${response.statusCode})"),
            margin: EdgeInsets.all(16),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    }
  }

  Future<Map<String, Object?>?> buildFeedbackJson() async {
    if (_feedbackType != null) {
      FeedbackDetails feedback = FeedbackDetails(
        type: _feedbackType!,
        subtype: _selectedOption,
        responseType: _responseOption,
        message: _textEditingController.text,
        email: (_responseNeeded ?? false) &&
                _responseOption == ResponseOption.email
            ? _emailTextController.text
            : null,
        worksheet: widget.worksheetPage,
        worksheetLang: widget.langCode,
      );

      Map<String, Object?> feedbackJson = await feedback.toJson(ref);

      print(feedbackJson);

      return feedbackJson;
    }
  }

  void checkCanSend() {
    setState(() {
      _canSend = _feedbackType != null &&
          _responseNeeded != null &&
          (!_responseNeeded! ||
              _responseOption != null &&
                  (_responseOption == ResponseOption.email
                      ? EmailValidator.validate(_emailTextController.text)
                      : true)) &&
          _textEditingController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    checkCanSend();

    return Scaffold(
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Opacity(
            opacity: _canSend ? 1.0 : 0.5,
            child: _sendButton(),
          ),
        ),
      ),
      appBar: AppBar(title: const Text("Get in touch")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 32, 0, 64),
          child: Column(
            children: [
              // Set app language
              _secureCommunicationInfoButton(),

              const SizedBox(height: 10),

              ListTile(
                title: const Text('I have a question'),
                leading: Radio<FeedbackType>(
                  value: FeedbackType.question,
                  groupValue: _feedbackType,
                  onChanged: (FeedbackType? value) {
                    setFeedbackType(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('I want to give feedback'),
                leading: Radio<FeedbackType>(
                  value: FeedbackType.feedback,
                  groupValue: _feedbackType,
                  onChanged: (FeedbackType? value) {
                    setFeedbackType(value);
                  },
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
                child: (_feedbackType == FeedbackType.feedback)
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: feedbackOptions.map((option) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ChoiceChip(
                              onSelected: (val) {
                                setSelectedOption(option);
                              },
                              label: Text(option),
                              selected: option == _selectedOption,
                            ),
                          );
                        }).toList()),
                      )
                    : Container(),
              ),
              ListTile(
                title: const Text('I want to request a trainer'),
                leading: Radio<FeedbackType>(
                  value: FeedbackType.trainer,
                  groupValue: _feedbackType,
                  onChanged: (FeedbackType? value) {
                    setFeedbackType(value);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _textEditingController,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (val) {
                    checkCanSend();
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: _hintTextForFeedbackType(_feedbackType)),
                ),
              ),
              const SizedBox(height: 32),
              Divider(),
              ListTile(
                title: const Text('I don\'t need a response'),
                enabled: _feedbackType == FeedbackType.feedback,
                leading: Radio<bool>(
                  value: false,
                  groupValue: _responseNeeded,
                  onChanged: _feedbackType != FeedbackType.feedback
                      ? null
                      : (bool? value) {
                          setResponseNeeded(false);
                        },
                ),
              ),
              ListTile(
                title: const Text('Please respond to me'),
                subtitle: const Text('Email or via the app…'),
                leading: Radio<bool>(
                  value: true,
                  groupValue: _responseNeeded,
                  onChanged: (bool? value) {
                    setResponseNeeded(true);
                  },
                ),
              ),
              if (_responseNeeded ?? false)
                SegmentedButton<ResponseOption?>(
                  segments: const [
                    ButtonSegment(
                        value: ResponseOption.email,
                        label: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text("Email"),
                        )),
                    ButtonSegment(
                        value: ResponseOption.app,
                        label: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text("In-app"),
                        ))
                  ],
                  selected: {_responseOption},
                  onSelectionChanged: (options) {
                    setState(() {
                      _responseOption = options.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Theme.of(context).primaryColor,
                  ),
                  multiSelectionEnabled: false,
                ),
              if (_responseNeeded ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _responseOptionWidget(),
                ),
              // const DesignSettings()
            ],
          ),
        ),
      ),
    );
  }

  String _hintTextForFeedbackType(FeedbackType? type) {
    switch (type) {
      case FeedbackType.question:
        return "Enter your question…";
      case FeedbackType.feedback:
        return "Enter your feedback…";
      case FeedbackType.trainer:
        return "Tell us about your request…";
      case null:
        return "";
    }
  }

  Widget _responseOptionWidget() {
    switch (_responseOption) {
      case ResponseOption.app:
        return Text(
            "You will receive a notification when we respond. You can also check for responses from the 'Responses' page of the app.");
      case ResponseOption.email:
        return Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
                controller: _emailTextController,
                decoration:
                    InputDecoration(hintText: "Enter your email address…"),
                validator: (value) {
                  if (value != null && EmailValidator.validate(value)) {
                    return null;
                  } else {
                    return "Please enter a valid email";
                  }
                }));
      case null:
        return Container();
    }
  }

  Widget _secureCommunicationInfoButton() {
    return TextButton.icon(
      style: TextButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          foregroundColor: Theme.of(context).colorScheme.onSurface),
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: Icon(Icons.lock_outline_rounded),
                title: Text(
                  "We handle your data securely.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            });
      },
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Communication is secure",
              style: Theme.of(context).textTheme.bodyLarge),
          Text("Tap for more info",
              style: Theme.of(context).textTheme.bodySmall)
        ],
      ),
      icon: Opacity(
        opacity: 0.8,
        child: const Icon(
          Icons.lock_outline_rounded,
        ),
      ),
    );
  }

  Widget _sendButton() {
    return TextButton.icon(
      style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface),
      onPressed: () {
        if (_canSend) {
          _sendFeedback();
        } else {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Error"),
                );
              });
        }
      },
      label: Text("Send",
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.black)),
      icon: Icon(
        Icons.send_rounded,
      ),
    );
  }
}

/// All settings regarding languages.
/// The main part of this is in [LanguagesTable]
class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      Align(
          alignment: Alignment.topLeft,
          child: Text(
            context.l10n.languages,
            style: Theme.of(context).textTheme.titleLarge,
          )),
      const SizedBox(height: 10),
      Text(
        context.l10n.languagesText,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 10),
      const Expanded(child: LanguagesTable()),
      const SizedBox(height: 10),
    ]);
  }
}

/// All settings about checking for updates
class UpdateSettings extends ConsumerWidget {
  const UpdateSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime lastCheck = ref.watch(lastCheckedProvider);
    // Convert into human readable string in local time
    DateTime localTime = lastCheck.add(DateTime.now().timeZoneOffset);
    String timestamp = DateFormat('yyyy-MM-dd HH:mm').format(localTime);

    return Column(children: [
      // Updates (headline)
      Align(
          alignment: Alignment.topLeft,
          child: Text(context.l10n.updates,
              style: Theme.of(context).textTheme.titleLarge)),
      // Check for updates TODO for version 0.9
/*      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(context.l10n.checkFrequency,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 20),
          const DropdownButtonCheckFrequency(),
        ],
      ),
      const SizedBox(height: 10),*/
      // Last check with date
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("${context.l10n.lastCheck} ",
            style: Theme.of(context).textTheme.bodyMedium),
        Text(timestamp, style: Theme.of(context).textTheme.bodyMedium)
      ]),
      const SizedBox(height: 10),
      // Check now
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [CheckNowButton(buttonText: context.l10n.checkNow)],
      ),
/*      const SizedBox(height: 10),
      // Do automatic updates TODO for version 0.9

      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(context.l10n.doAutomaticUpdates,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 20),
          const DropdownButtonAutomaticUpdates(),
        ],
      ),*/
    ]);
  }
}
