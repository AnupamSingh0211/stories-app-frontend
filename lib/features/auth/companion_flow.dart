import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CompanionFlowComplete = void Function(BuildContext context);

final companionSelectionPendingProvider = StateProvider<bool>((ref) => false);
