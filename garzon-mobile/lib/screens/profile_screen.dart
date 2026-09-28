import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../services/profile_photo_service.dart';
import '../services/local_avatar_service.dart';
import '../widgets/profile_avatar.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

// Lab Activity 4 - Enhancement 3: Render the authenticated, saved User model.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user = widget.user;
  bool _loading = false;
  bool _savingPhoto = false;
  String? _photoUrl;
  String? _avatar;
  String get _avatarAccount => '${_user.loginType.name}.${_user.accountId}';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _refresh();
      if (!mounted) return;
      final String? avatar = await LocalAvatarService().load(_avatarAccount);
      if (!mounted) return;
      setState(() => _avatar = avatar);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final XFile? recovered = await ProfilePhotoService().recover();
        if (mounted && recovered != null) {
          await _changePhoto(recovered: recovered);
        }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not recover the selected photo: $error');
      }
    }
  }

  Future<void> _chooseAvatar() async {
    try {
      final String? choice = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext context) => SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .72,
            minChildSize: .4,
            maxChildSize: .9,
            builder: (BuildContext context, ScrollController controller) =>
                ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: <Widget>[
                    Text(
                      'Choose your avatar',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pick your campus character or add a photo. Icons and local photos stay on this device.',
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: .9,
                      children: profileIcons.entries.map((
                        MapEntry<String, IconData> entry,
                      ) {
                        final bool selected = _avatar == 'icon:${entry.key}';
                        final ColorScheme colors = Theme.of(
                          context,
                        ).colorScheme;
                        return Semantics(
                          selected: selected,
                          button: true,
                          label: entry.key,
                          child: Material(
                            color: selected
                                ? colors.primaryContainer
                                : colors.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: selected
                                    ? colors.primary
                                    : colors.outlineVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () =>
                                  Navigator.pop(context, 'icon:${entry.key}'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    entry.value,
                                    size: 36,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(entry.key),
                                  if (selected)
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: colors.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Choose from gallery'),
                      subtitle: const Text('Save on this device'),
                      onTap: () => Navigator.pop(context, 'local'),
                    ),
                    if (_user.loginType == LoginType.firebase)
                      ListTile(
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: const Text('Sync a photo to my account'),
                        subtitle: const Text(
                          'Choose a photo to use across devices',
                        ),
                        onTap: () => Navigator.pop(context, 'cloud'),
                      ),
                    if (_avatar != null)
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'reset'),
                        child: const Text('Use account avatar'),
                      ),
                  ],
                ),
          ),
        ),
      );
      if (!mounted || choice == null) return;
      if (choice == 'local' || choice == 'cloud') {
        await _changePhoto(sync: choice == 'cloud');
      } else {
        final String? selection = choice == 'reset' ? null : choice;
        await LocalAvatarService().save(_avatarAccount, selection);
        if (mounted) setState(() => _avatar = selection);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your avatar: $error')),
        );
      }
    }
  }

  Future<void> _changePhoto({XFile? recovered, bool sync = false}) async {
    if (_savingPhoto || _loading) return;
    setState(() => _savingPhoto = true);
    try {
      final ProfilePhotoService service = ProfilePhotoService();
      final XFile? selected = recovered ?? await service.pick();
      if (selected == null || !mounted) return;
      final Uint8List bytes = await service.prepare(selected);
      if (!mounted) return;
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Use this profile picture?'),
          content: SizedBox.square(
            dimension: 200,
            child: ClipOval(child: Image.memory(bytes, fit: BoxFit.cover)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save photo'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      if (sync) {
        final String? uid = _user.firebaseUid;
        if (uid == null) {
          throw StateError('Sign in with Firebase to sync a photo.');
        }
        final String url = await service.save(uid, bytes);
        await LocalAvatarService().save(_avatarAccount, null);
        if (!mounted) return;
        setState(() {
          _photoUrl = url;
          _avatar = null;
        });
      } else {
        final LocalAvatarService local = LocalAvatarService();
        final String selection = local.photo(bytes);
        await local.save(_avatarAccount, selection);
        if (!mounted) return;
        setState(() => _avatar = selection);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sync
                  ? 'Could not sync your photo. Check your connection and Firebase Storage setup. $error'
                  : 'Could not save your photo. Check photo permissions or choose another image. $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final User? user = await context.read<UserService>().getUserData();
      if (!mounted) return;
      if (user == null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(SignInScreen.routeName, (_) => false);
      } else {
        setState(() => _user = user);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User user = _user;
    final String image = _photoUrl ?? user.image;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: <Widget>[
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...<Widget>[
          Text(_error!, style: TextStyle(color: colors.error)),
          TextButton(
            onPressed: _loading ? null : _refresh,
            child: const Text('Retry profile'),
          ),
        ],
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                ProfileAvatar(selection: _avatar, remoteImage: image),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _savingPhoto || _loading ? null : _chooseAvatar,
                  icon: _savingPhoto
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    _savingPhoto ? 'Updating avatar…' : 'Choose avatar',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.fullName.isEmpty ? user.username : user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${user.username}',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Account details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              _ProfileDetail(
                icon: Icons.login_rounded,
                label: 'Login type',
                value: user.loginType == LoginType.firebase
                    ? 'Firebase'
                    : 'DummyJSON',
              ),
              _ProfileDetail(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              if (user.loginType == LoginType.dummyJson)
                _ProfileDetail(
                  icon: Icons.person_outline_rounded,
                  label: 'Gender',
                  value: user.gender,
                ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ProfileDetail(
                icon: Icons.badge_outlined,
                label: 'User ID',
                value: user.accountId,
              ),
              if (user.loginType == LoginType.firebase) ...<Widget>[
                _ProfileDetail(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: user.age?.toString() ?? '',
                ),
                _ProfileDetail(
                  icon: Icons.phone_outlined,
                  label: 'Contact number',
                  value: user.contactNo,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (user.loginType == LoginType.firebase) ...<Widget>[
          if (!user.profileComplete)
            FilledButton.tonal(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => SignUpScreen(user: user),
                      ),
                    ),
              child: const Text('Complete your profile'),
            ),
          const SizedBox(height: 20),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'DummyJSON accounts are demo accounts. Create a Firebase account '
              'to manage your username, password, and account deletion.',
            ),
          ),
      ],
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label),
    subtitle: SelectableText(value.isEmpty ? 'Not provided' : value),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  );
}
