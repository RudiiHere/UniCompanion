import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';
import '/crop_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _studentIdCtrl;
  late final TextEditingController _deptCtrl;

  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.fullName);
    _studentIdCtrl = TextEditingController(text: p.studentId ?? '');
    _deptCtrl = TextEditingController(text: p.department ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;

      final original = await picked.readAsBytes();
      if (!mounted) return;


      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => AvatarCropScreen(imageBytes: original)),
      );
      if (cropped == null) return;


      final isPng = cropped.length > 1 && cropped[0] == 0x89 && cropped[1] == 0x50;

      setState(() {
        _pickedBytes = cropped;
        _pickedExt = isPng ? 'png' : 'jpg';
      });
    } catch (_) {
      setState(() => _error = 'Could not open the photo.');
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }

    setState(() => _saving = true);
    final auth = ref.read(authServiceProvider);

    try {

      String? avatarUrl = widget.profile.avatarUrl;
      if (_pickedBytes != null) {
        try {
          final url = await auth.uploadAvatar(_pickedBytes!, _pickedExt);
          if (url == null) {
            setState(() {
              _saving = false;
              _error = 'You must be signed in to upload a photo.';
            });
            return;
          }
          avatarUrl = url;
        } on StorageException catch (e) {
          setState(() {
            _saving = false;
            _error = 'Photo upload failed: ${e.message}\n'
                'In Supabase, create a public Storage bucket named "avatars".';
          });
          return;
        } catch (e) {
          setState(() {
            _saving = false;
            _error = 'Photo upload failed: $e';
          });
          return;
        }
      }


      final updated = UserProfile(
        id: widget.profile.id,
        email: widget.profile.email,
        fullName: name,
        avatarUrl: avatarUrl,
        studentId: _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim(),
        department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        semester: widget.profile.semester,
        role: widget.profile.role,
        createdAt: widget.profile.createdAt,
      );

      final ok = await auth.updateProfile(updated);
      if (!ok) {
        setState(() {
          _saving = false;
          _error = 'Could not save your profile. Check your connection.';
        });
        return;
      }

      ref.invalidate(currentProfileProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.profile;
    final initials = p.fullName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [

          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.indigoSoft,
                    border: Border.all(color: AppTheme.indigo.withOpacity(0.25), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _avatarContent(initials),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _saving ? null : _pickImage,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.indigo,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _saving ? null : _pickImage,
              child: const Text('Change photo'),
            ),
          ),
          const SizedBox(height: 12),

          _label('Full name'),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 14),

          _label('Email'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.email,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ),
                Icon(Icons.lock_outline_rounded, size: 15, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Email can\'t be changed here.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          _label('Student ID'),
          TextField(
            controller: _studentIdCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. 2021331045',
              prefixIcon: Icon(Icons.badge_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 14),

          _label('Department'),
          TextField(
            controller: _deptCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Computer Science',
              prefixIcon: Icon(Icons.school_outlined, size: 18),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.rose, fontSize: 12, fontWeight: FontWeight.w500)),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Widget _avatarContent(String initials) {
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!, fit: BoxFit.cover, width: 96, height: 96);
    }
    final url = widget.profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorWidget: (_, __, ___) => _initialsBox(initials),
      );
    }
    return _initialsBox(initials);
  }

  Widget _initialsBox(String initials) => Center(
    child: Text(
      initials,
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.indigo),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}