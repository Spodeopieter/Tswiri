import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_google_ml_kit/extentions/capitalize_first_character.dart';
import 'package:flutter_google_ml_kit/functions/isar_functions/isar_functions.dart';
import 'package:flutter_google_ml_kit/global_values/global_colours.dart';
import 'package:flutter_google_ml_kit/isar_database/containers/container_entry/container_entry.dart';
import 'package:flutter_google_ml_kit/isar_database/containers/photo/photo.dart';
import 'package:flutter_google_ml_kit/isar_database/tags/ml_tag/ml_tag.dart';
import 'package:flutter_google_ml_kit/isar_database/tags/tag_text/tag_text.dart';
import 'package:flutter_google_ml_kit/isar_database/tags/user_tag/user_tag.dart';
import 'package:flutter_google_ml_kit/views/containers/container_view.dart';

import 'package:flutter_google_ml_kit/views/gallery/image_painter.dart.dart';
import 'package:flutter_google_ml_kit/views/widgets/dividers/dividers.dart';
import 'package:isar/isar.dart';

class GalleryView extends StatefulWidget {
  const GalleryView({Key? key}) : super(key: key);

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  ///List of all Photos.
  List<Photo> photos = [];

  ///Selected Photo.
  Photo? selectedPhoto;

  //List<MlTag> mlTags = [];
  List<int> assignedTagIDs = [];

  late List<TagText> tagTexts = isarDatabase!.tagTexts.where().findAllSync();
  List<UserTag> userTags = [];

  TextEditingController tagsController = TextEditingController();
  final _tagsNode = FocusNode();
  bool showTagEditor = false;

  @override
  void initState() {
    updatePhotos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
      bottomSheet: _bottomSheet(),
    );
  }

  ///APP BAR///

  AppBar _appBar() {
    return AppBar(
      backgroundColor: sunbirdOrange,
      elevation: 25,
      centerTitle: true,
      title: _title(),
      shadowColor: Colors.black54,
      automaticallyImplyLeading: false,
      leading: IconButton(
          onPressed: () {
            setState(() {
              if (selectedPhoto == null) {
                Navigator.pop(context);
              } else {
                selectedPhoto = null;
                _tagsNode.unfocus();
                showTagEditor = false;
              }
            });
          },
          icon: const Icon(Icons.arrow_back)),
      actions: [
        Visibility(
          visible: selectedPhoto != null,
          child: TextButton(
            onPressed: () {
              ContainerEntry container = isarDatabase!.containerEntrys
                  .filter()
                  .containerUIDMatches(selectedPhoto!.containerUID)
                  .findFirstSync()!;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContainerView(
                    containerEntry: container,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  'Go to Container',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Icon(
                  Icons.navigate_next_sharp,
                  color: Colors.white,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Text _title() {
    return Text(
      'Gallery',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  ///BODY///
  Widget _body() {
    return Builder(builder: (context) {
      if (photos.isEmpty) {
        return const Center(
          child: Text('Take some photos.'),
        );
      }

      if (selectedPhoto == null) {
        return _photoGridView();
      } else {
        return _photoEditor();
      }
    });
  }

  ///GRID VIEW///
  Widget _photoGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 1.0,
        crossAxisCount: 3,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return photoCard(photos[index]);
      },
    );
  }

  Widget photoCard(Photo containerPhoto) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPhoto = containerPhoto;
        });
      },
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.5), // Image border
          child: SizedBox.fromSize(
            child: Image.file(
              File(containerPhoto.photoPath),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  String? swipeDirection;

  ///PHOTO EDITOR///
  Widget _photoEditor() {
    return GestureDetector(
      onPanUpdate: (details) {
        swipeDirection = details.delta.dx < 0 ? 'right' : 'left';
      },
      onPanEnd: (details) {
        if (swipeDirection == null) {
          return;
        }
        if (swipeDirection == 'right') {
          log('right');
          int index = photos.indexOf(selectedPhoto!);
          if (index < photos.length - 1) {
            setState(() {
              selectedPhoto = photos[index + 1];
            });
          }
        }
        if (swipeDirection == 'left') {
          log('left');
          int index = photos.indexOf(selectedPhoto!);
          if (index > 0) {
            setState(() {
              selectedPhoto = photos[index - 1];
            });
          }
        }
      },
      child: SingleChildScrollView(
        child: FutureBuilder<Size>(
          future: getImageSize(selectedPhoto!),
          builder: ((context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Column(
                children: [
                  _userTagsCard(),
                  imageViewer(snapshot.data!),
                  _mlTagsCard(),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
        ),
      ),
    );
  }

  Widget imageViewer(Size size) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.white12,
      elevation: 5,
      shadowColor: Colors.black26,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(selectedPhoto!.photoPath),
              fit: BoxFit.fill,
            ),
            FutureBuilder<Size>(
                future: getImageSize(selectedPhoto!),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return CustomPaint(
                      painter: ObjectPainter(
                          photo: selectedPhoto!, absoluteSize: snapshot.data!),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                })
          ],
        ),
      ),
    );
  }

  ///USER TAGS///
  Widget _userTagsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.white12,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: sunbirdOrange, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _userTagsHeading(),
            _dividerHeading(),
            _userTagsBuilder(),
          ],
        ),
      ),
    );
  }

  Widget _userTagsHeading() {
    return Text('UserTags', style: Theme.of(context).textTheme.headlineSmall);
  }

  Widget _userTagsBuilder() {
    return Builder(builder: (context) {
      userTags = isarDatabase!.userTags
          .filter()
          .photoIDEqualTo(selectedPhoto!.id)
          .findAllSync();

      List<Widget> tags = [_addTag()];
      tags.addAll(userTags.map((e) => userTag(e)));

      return Wrap(
        spacing: 10,
        alignment: WrapAlignment.start,
        runSpacing: 2,
        children: tags,
      );
    });
  }

  Widget userTag(UserTag userTag) {
    return Builder(builder: (context) {
      String tagText = isarDatabase!.tagTexts.getSync(userTag.textID)!.text;
      return ActionChip(
        label: Text(tagText),
        onPressed: () {
          setState(() {
            userTags.remove(userTag);
            isarDatabase!
                .writeTxnSync((isar) => isar.userTags.deleteSync(userTag.id));
          });
        },
        backgroundColor: sunbirdOrange,
      );
    });
  }

  ///ML TAGS///
  Widget _mlTagsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.white12,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: sunbirdOrange, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _mlTagsHeading(),
            _dividerHeading(),
            _mlTagsBuilder(),
          ],
        ),
      ),
    );
  }

  Widget _mlTagsHeading() {
    return Text('AI Tags', style: Theme.of(context).textTheme.headlineSmall);
  }

  Builder _mlTagsBuilder() {
    return Builder(builder: (context) {
      //Photo's MlTags.
      List<MlTag> mlTags = isarDatabase!.mlTags
          .filter()
          .photoIDEqualTo(selectedPhoto!.id)
          .and()
          .blackListedEqualTo(false)
          .findAllSync();

      //Blacklisted MlTags.
      List<MlTag> blacklistedMlTags = isarDatabase!.mlTags
          .filter()
          .photoIDEqualTo(selectedPhoto!.id)
          .and()
          .blackListedEqualTo(true)
          .findAllSync();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 5,
            runSpacing: 2.5,
            children: mlTags
                .map((e) => mlTagChip(e, mlTags, blacklistedMlTags))
                .toList(),
          ),
          lightDivider(height: 16),
          Text(
            'Blacklist',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          headingDivider(),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: blacklistedMlTags
                .map((e) => mlTagChip(e, mlTags, blacklistedMlTags))
                .toList(),
          ),
        ],
      );
    });
  }

  ActionChip mlTagChip(
      MlTag mlTag, List<MlTag> mlTags, List<MlTag> blacklistedMlTags) {
    return ActionChip(
      avatar: Builder(builder: (context) {
        switch (mlTag.tagType) {
          case MlTagType.text:
            return const Icon(
              Icons.format_size,
              size: 15,
            );

          case MlTagType.objectLabel:
            return const Icon(
              Icons.emoji_objects,
              size: 15,
            );

          case MlTagType.imageLabel:
            return const Icon(
              Icons.image,
              size: 15,
            );
        }
      }),
      label: Text(
        isarDatabase!.tagTexts.getSync(mlTag.textID)?.text ?? 'error',
      ),
      onPressed: () {
        if (mlTags.contains(mlTag)) {
          setState(() {
            //Move to blacklist.
            mlTags.remove(mlTag);
            blacklistedMlTags.add(mlTag);
          });

          //Write to database.
          mlTag.blackListed = true;
          isarDatabase!.writeTxn(
              (isar) => isar.mlTags.put(mlTag, replaceOnConflict: true));
        } else {
          setState(() {
            //Move to mlTags.
            mlTags.add(mlTag);
            blacklistedMlTags.remove(mlTag);
          });

          //Write to database.
          mlTag.blackListed = false;
          isarDatabase!.writeTxn(
              (isar) => isar.mlTags.put(mlTag, replaceOnConflict: true));
        }
      },
      tooltip: mlTag.tagType.name.toString().capitalize(),
      backgroundColor: sunbirdOrange,
    );
  }

  ///NEW USER TAGS///
  Widget _bottomSheet() {
    return Visibility(
      visible: showTagEditor,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: sunbirdOrange, width: 1),
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _tagSelector(),
            _divider(),
            _tagTextField(),
          ],
        ),
      ),
    );
  }

  Widget _addTag() {
    return Visibility(
      visible: !showTagEditor,
      child: InputChip(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: () {
          setState(() {
            _tagsNode.requestFocus();
            showTagEditor = !showTagEditor;
          });
        },
        label: const Text('+'),
      ),
    );
  }

  Widget _tagSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      scrollDirection: Axis.horizontal,
      child: Builder(builder: (context) {
        List<TagText> tagTexts = [];

        if (tagsController.text.isNotEmpty) {
          tagTexts.addAll(isarDatabase!.tagTexts
              .filter()
              .textMatches(tagsController.text.toLowerCase())
              .and()
              .not()
              .repeat(
                  userTags, (q, UserTag element) => q.idEqualTo(element.textID))
              .findAllSync());
        } else {
          List<int> usr = userTags.map((e) => e.textID).toList();
          tagTexts.addAll(isarDatabase!.tagTexts
              .filter()
              .not()
              .repeat(
                  userTags, (q, UserTag element) => q.idEqualTo(element.textID))
              .findAllSync()
              .where((element) => !usr.contains(element.id)));
        }

        return Wrap(
          spacing: 5,
          children: tagTexts.map((e) => tagText(e)).toList(),
        );
      }),
    );
  }

  Widget tagText(TagText tagText) {
    return ActionChip(
      label: Text(tagText.text),
      onPressed: () {
        List<int> usr = userTags.map((e) => e.textID).toList();
        if (!usr.contains(tagText.id)) {
          UserTag newUserTag = UserTag()
            ..textID = tagText.id
            ..photoID = selectedPhoto!.id;
          userTags.add(newUserTag);
          isarDatabase!
              .writeTxnSync((isar) => isar.userTags.putSync(newUserTag));
        }

        setState(() {});
      },
      backgroundColor: sunbirdOrange,
    );
  }

  Widget _tagTextField() {
    return TextField(
      controller: tagsController,
      focusNode: _tagsNode,
      onChanged: (value) {
        setState(() {});
      },
      onSubmitted: (value) {
        addTag();
        if (value.isEmpty) {
          setState(() {
            showTagEditor = false;
          });
        }
      },
      style: const TextStyle(fontSize: 18),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        labelText: 'Tag',
        labelStyle: const TextStyle(fontSize: 15, color: Colors.white),
        suffixIcon: IconButton(
          onPressed: () {
            addTag();
          },
          icon: const Icon(Icons.add),
        ),
        border: const OutlineInputBorder(
            borderSide: BorderSide(color: sunbirdOrange)),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: sunbirdOrange)),
      ),
    );
  }

  void addTag() {
    if (tagsController.text.isNotEmpty) {
      //1. Get Text.
      String text = tagsController.text.toLowerCase();

      //2. Check if it exists.
      TagText? tagText =
          isarDatabase!.tagTexts.filter().textMatches(text).findFirstSync();

      if (tagText != null) {
        List<int> usr = userTags.map((e) => e.textID).toList();

        if (!usr.contains(tagText.id)) {
          //Create new
          UserTag userTag = UserTag()
            ..textID = tagText.id
            ..photoID = selectedPhoto!.id;

          isarDatabase!.writeTxnSync((isar) => isar.userTags.putSync(userTag));
          _tagsNode.requestFocus();
          setState(() {});
        }
      } else {
        TagText newTagText = TagText()..text = text;
        isarDatabase!.writeTxnSync((isar) => isar.tagTexts.putSync(newTagText));

        //Create new
        UserTag userTag = UserTag()
          ..textID = newTagText.id
          ..photoID = selectedPhoto!.id;

        isarDatabase!.writeTxnSync((isar) => isar.userTags.putSync(userTag));
        userTags.add(userTag);
        _tagsNode.requestFocus();
        tagsController.clear();
        setState(() {});
      }
    }
  }

  ///FUNCTIONS///
  void updatePhotos() {
    setState(() {
      photos = isarDatabase!.photos.where().findAllSync();
    });
  }

  Future<Size> getImageSize(Photo selectedPhoto) async {
    var decodedImage = await decodeImageFromList(
        File(selectedPhoto.photoPath).readAsBytesSync());

    Size absoluteSize =
        Size(decodedImage.height.toDouble(), decodedImage.width.toDouble());

    return absoluteSize;
  }

  ///MISC///

  Divider _divider() {
    return const Divider(
      height: 8,
      indent: 2,
      color: Colors.white30,
    );
  }

  Divider _dividerHeading() {
    return const Divider(
      height: 8,
      thickness: 1,
      color: Colors.white,
    );
  }
}
