import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/quick_admission_remote_data_source.dart';
import '../../data/repositories/quick_admission_repository_impl.dart';
import '../cubit/quick_admission_cubit.dart';
import '../cubit/quick_admission_state.dart';

class DepositSlipViewerPage extends StatefulWidget {
  final int cc;

  const DepositSlipViewerPage({super.key, required this.cc});

  @override
  State<DepositSlipViewerPage> createState() => _DepositSlipViewerPageState();
}

class _DepositSlipViewerPageState extends State<DepositSlipViewerPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuickAdmissionCubit(
        repository: QuickAdmissionRepositoryImpl(
          remoteDataSource: QuickAdmissionRemoteDataSourceImpl(InjectionContainer.dio),
        ),
      )..fetchDepositSlip(widget.cc),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Deposit Slip - CC ${widget.cc}'),
          centerTitle: true,
        ),
        body: BlocConsumer<QuickAdmissionCubit, QuickAdmissionState>(
          listener: (context, state) {
            if (state is QuickAdmissionPdfFailure) {
              showAppSnackBar(context, state.message, type: AppSnackBarType.error);
            }
          },
          builder: (context, state) {
            if (state is QuickAdmissionPdfLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppTheme.space4),
                    Text(
                      'Generating Deposit Slip PDF...',
                      style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            if (state is QuickAdmissionPdfSuccess) {
              final pdfBytes = state.pdfBytes;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.blue100, width: 2),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppTheme.navy,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space6),
                      Text(
                        'Deposit Slip PDF Generated',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space2),
                      const Text(
                        'Click below to open and review the generated deposit slip.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.blue300),
                      ),
                      const SizedBox(height: AppTheme.space6),
                      CustomButton(
                        text: 'Open PDF',
                        onPressed: () => _openPdf(pdfBytes),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      CustomButton(
                        text: 'Save to Device',
                        isPrimary: false,
                        isLoading: _isSaving,
                        onPressed: () => _savePdf(pdfBytes),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                  const SizedBox(height: AppTheme.space3),
                  const Text('Failed to load PDF'),
                  const SizedBox(height: AppTheme.space4),
                  ElevatedButton(
                    onPressed: () {
                      context.read<QuickAdmissionCubit>().fetchDepositSlip(widget.cc);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPdf(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/DepositSlip_${widget.cc}.pdf';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(tempPath);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not open the PDF viewer', type: AppSnackBarType.error);
      }
    }
  }

  Future<void> _savePdf(Uint8List bytes) async {
    setState(() => _isSaving = true);
    final fileName = 'DepositSlip_${widget.cc}.pdf';
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      String? savedPath;

      if (kIsWeb) {
        throw UnsupportedError('Saving file directly is only supported on mobile devices.');
      }

      if (Platform.isAndroid || Platform.isIOS) {
        savedPath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: tempPath,
            fileName: fileName,
          ),
        );
      } else {
        final downloads = await getDownloadsDirectory();
        final targetDir = downloads ?? await getApplicationDocumentsDirectory();
        savedPath = '${targetDir.path}/$fileName';
        await File(savedPath).writeAsBytes(bytes, flush: true);
      }

      if (savedPath != null && mounted) {
        showAppSnackBar(context, 'Saved deposit slip PDF to device!', type: AppSnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save PDF to device', type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
