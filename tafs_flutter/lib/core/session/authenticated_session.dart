import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/student.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/support_tickets/presentation/bloc/support_ticket_list_bloc.dart';
import '../../features/support_tickets/presentation/bloc/support_ticket_list_event.dart';
import '../../injection_container.dart';
import '../services/fcm_registration_service.dart';
import 'session_reset.dart';

/// Starts chat, support tickets, and FCM registration for a logged-in parent.
void startAuthenticatedSession(
  BuildContext context, {
  List<Student>? students,
}) {
  if (students != null) {
    syncSelectedStudent(context, students);
  }

  unawaited(
    FcmRegistrationService.instance.registerWithBackend(InjectionContainer.dio),
  );

  context.read<ChatBloc>().add(ChatSessionStartRequested());
  context.read<SupportTicketListBloc>().add(
        const SupportTicketListLoadRequested(),
      );
}
