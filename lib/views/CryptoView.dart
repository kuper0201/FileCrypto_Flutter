import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:desktop_drop/desktop_drop.dart';

import 'package:file_crypto/utils/DirManager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

typedef CryptoAction = Future<void> Function(
    List<String> files, String password, ProgressDialog pd);

class CryptoView extends StatefulWidget {
  final String title;
  final IconData headerIcon;
  final String actionLabel;
  final String passwordHint;
  final CryptoAction onCrypto;
  final String foregroundTitle;
  final Color accentColor;

  const CryptoView({
    Key? key,
    required this.title,
    required this.headerIcon,
    required this.actionLabel,
    required this.passwordHint,
    required this.onCrypto,
    required this.foregroundTitle,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<CryptoView> createState() => _CryptoViewState();
}

class _CryptoViewState extends State<CryptoView>
    with SingleTickerProviderStateMixin {
  Set<String> files = {};
  List<String> get fileList => files.toList();
  bool _isDragging = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.videocam_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audiotrack_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'chacha':
        return Icons.enhanced_encryption_outlined;
      case 'txt':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatSize(String path) {
    try {
      final f = File(path);
      final bytes = f.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1073741824) {
        return '${(bytes / 1048576).toStringAsFixed(1)} MB';
      }
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    } catch (_) {
      return '';
    }
  }

  void _performAction(String password) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a password'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (Platform.isAndroid) {
      await FlutterForegroundTask.startService(
        notificationTitle: widget.foregroundTitle,
        notificationText: "Processing...",
      );
      await DirManager().checkFirstUri();
    }

    ProgressDialog pd = ProgressDialog(context: context);
    final colorScheme = Theme.of(context).colorScheme;

    pd.show(
        max: files.length,
        msg: "${widget.title}ing...",
        progressType: ProgressType.valuable,
        backgroundColor: colorScheme.surface,
        msgColor: colorScheme.onSurface,
        valueColor: colorScheme.primary);

    try {
      await widget.onCrypto(fileList, password, pd);
    } catch (e) {
      pd.close();

      if (Platform.isAndroid) {
        FilePicker.platform.clearTemporaryFiles();
        FlutterForegroundTask.stopService();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('mac check')
                ? 'Wrong password or corrupted file'
                : 'Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (Platform.isAndroid) {
      FilePicker.platform.clearTemporaryFiles();
      FlutterForegroundTask.stopService();
    }

    final count = files.length;
    setState(() {
      files.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$count file${count > 1 ? 's' : ''} ${widget.title.toLowerCase()}ed successfully'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPasswordDialog() {
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add files first'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final pwEditController = TextEditingController();
    bool obscureText = true;

    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.vpn_key_outlined,
                      color: widget.accentColor, size: 22),
                  const SizedBox(width: 10),
                  const Text("Enter Password"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pwEditController,
                    autofocus: true,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      hintText: widget.passwordHint,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                          icon: Icon(obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () {
                            setDialogState(() {
                              obscureText = !obscureText;
                            });
                          }),
                    ),
                    onSubmitted: (value) {
                      Navigator.pop(dialogContext);
                      _performAction(pwEditController.text);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${files.length} file${files.length > 1 ? 's' : ''} selected',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("Cancel")),
                FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _performAction(pwEditController.text);
                    },
                    child: Text(widget.actionLabel)),
              ],
            );
          });
        });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      final newFiles = <String>[];
      for (var fl in result.files) {
        if (fl.path != null && !files.contains(fl.path)) {
          newFiles.add(fl.path!);
        }
      }
      if (newFiles.isNotEmpty) {
        setState(() {
          files.addAll(newFiles);
        });
        _animController.reset();
        _animController.forward();
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      files.remove(fileList[index]);
    });
  }

  void _clearAll() {
    setState(() {
      files.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DropTarget(
        onDragEntered: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onDragExited: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onDragDone: (detail) {
          setState(() {
            _isDragging = false;
          });
          if (detail.files.isNotEmpty) {
            for (var f in detail.files) {
              files.add(f.path);
            }
            _animController.reset();
            _animController.forward();
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(colorScheme),
                if (files.isNotEmpty) _buildFileCountBar(colorScheme),
                Expanded(
                  child: files.isEmpty
                      ? _buildEmptyState(colorScheme, isDark)
                      : _buildFileList(colorScheme),
                ),
              ],
            ),
            _buildFAB(colorScheme),
            if (_isDragging) _buildDragOverlay(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(widget.headerIcon, color: widget.accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'ChaCha20 encryption',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCountBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            '${files.length} file${files.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: widget.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          TextButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 56,
                  color: widget.accentColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add files to ${widget.title.toLowerCase()}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below or drag & drop files here',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 180),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final path = fileList[index];
          final name = path.split(Platform.pathSeparator).last;
          final size = _formatSize(path);

          return Dismissible(
            key: Key(path),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeFile(index),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline,
                  color: colorScheme.error, size: 24),
            ),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _removeFile(index),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_fileIcon(name),
                            color: widget.accentColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (size.isNotEmpty)
                              Text(
                                size,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.close,
                          size: 20,
                          color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB(ColorScheme colorScheme) {
    final hasFiles = files.isNotEmpty;

    return Positioned(
      right: 16,
      bottom: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: hasFiles
            ? FloatingActionButton.extended(
                key: const ValueKey('action'),
                heroTag: 'action',
                onPressed: _showPasswordDialog,
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                elevation: 2,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  widget.actionLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              )
            : FloatingActionButton(
                key: const ValueKey('add'),
                heroTag: 'add',
                onPressed: _pickFiles,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                foregroundColor: colorScheme.onSurface,
                elevation: 1,
                child: const Icon(Icons.add, size: 28),
              ),
      ),
    );
  }

  Widget _buildDragOverlay(ColorScheme colorScheme) {
    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.4),
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_download_outlined,
                size: 48, color: widget.accentColor.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'Drop files here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.accentColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
