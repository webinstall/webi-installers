---
title: atomicparsley
homepage: https://github.com/wez/atomicparsley
tagline: |
  AtomicParsley is a lightweight tool for reading, parsing and setting iTunes-style metadata.
---

To update or switch versions, run `webi atomicparsley@stable` (or `@v20221229`,
`@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/AtomicParsley
```

**Windows Users**

```text
\Windows\System32\vcruntime140.dll
```

This will also attempt to install the
[Microsoft Visual C++ Redistributable](/vcruntime) via `webi vcruntime`. If it
fails and you get the error _`vcruntime140.dll` was not found_, you'll need to
[install it manually](https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170).

## Cheat Sheet

> `AtomicParsley` is an alternative to `ffmpeg` and `ffprobe` for viewing and
> changing metadata in MPEG-4 files with .3gp, .3g2, .mp4, .m4a, .m4b, .m4p,
> .m4r, and .m4v extensions. Because it's purpose-built for MP4 containers, it
> can do some things `ffmpeg` can't.

### How to Change Album Art

1. Save any existing cover art
   ```sh
   AtomicParsley ./my-song.m4a --extractPixToPath ./ 'my-song'
   ```
2. Remove the artwork
   ```sh
   AtomicParsley ./my-song.m4a --artwork REMOVE_ALL
   ```
3. **(macOS ONLY)** Add new artwork at the specified DPI (and other constraints)

   ```sh
   export PIC_OPTIONS="DPI=72"

   AtomicParsley ./my-podcast-audiobook.m4b --artwork ./my-season-1-cover.jpg
   ```

Only JPEG and PNG are supported. See `PIC_OPTIONS` down below for more options.
If you get an error, try exporting your file with a DPI to 72 (or up to 300 with
`PIC_OPTIONS` set) and a smaller resolution - perhaps 600x600 or 1500x1500 (what
old versions iTunes versions used).

### How to Remove Apple Account Info

```sh
AtomicParsley ./my-file.m4a \
    --DeepScan \
    --manualAtomRemove "moov.trak.mdia.minf.stbl.mp4a.pinf" \
    --manualAtomRemove "moov.udta.meta.ilst.apID" \
    --manualAtomRemove "moov.udta.meta.ilst.cnID" \
    --manualAtomRemove "moov.udta.meta.ilst.purd" \
    --manualAtomRemove "moov.udta.meta.ilst.sfID" \
    --manualAtomRemove "moov.udta.meta.ilst.soal" \
    --manualAtomRemove "moov.udta.meta.ilst.xid"
```

If you wanted to also remove information that indicates which Country or
Language the song was purchased in, or which album it was purchased from, there
are some additional IDs to consider:

| Metadata Tag                             | Description                                  |
| ---------------------------------------- | -------------------------------------------- |
| moov.udta.meta.ilst.apID                 | Apple account email address                  |
| moov.udta.meta.ilst.ownr                 | Apple account username                       |
| moov.udta.meta.ilst.atID                 | Artist-track ID                              |
| moov.udta.meta.ilst.cnID                 | iTunes Catalog ID                            |
| moov.udta.meta.ilst.geID                 | Genre ID                                     |
| moov.udta.meta.ilst.plID                 | Playlist ID (identifies album)               |
| moov.udta.meta.ilst.sfID                 | iTunes store identifier (location/number)    |
| moov.udta.meta.ilst.cprt                 | Copyright information                        |
| moov.udta.meta.ilst.flvr                 | Bitrate/video size related                   |
| moov.udta.meta.ilst.purd                 | Date purchased                               |
| moov.udta.meta.ilst.rtng                 | Explicit/Clean information                   |
| moov.udta.meta.ilst.soal                 | Album sort name                              |
| moov.udta.meta.ilst.stik                 | Media type information                       |
| moov.udta.meta.ilst.xid                  | Vendor xID                                   |
| moov.udta.meta.ilst.----.name:[iTunMOVI] | Embedded plist contains filesize and flavor. |
| moov.trak.mdia.minf.stbl.stsd.mp4a.pinf  | Purchase information related                 |

See <https://gist.github.com/riophae/f5694fd2952cb64982689b971ca6ec79>.

### Genre Lists

All values are **case sensitive**.

#### The "stik" List

These values are **case sensitive**:

0. `Home Video`
1. `Normal` (meaning music)
2. `Audiobook` (changes extension to .m4b)
3. `Whacked Bookmark`
4. `Music Video`
5. `Movie`
6. `Short Film`
7. `TV Show`
8. `Booklet`

#### Standard Music Genres

```txt
(1.)  Blues
(2.)  Classic Rock
(3.)  Country
(4.)  Dance
(5.)  Disco
(6.)  Funk
(7.)  Grunge
(8.)  Hip-Hop
(9.)  Jazz
(10.)  Metal
(11.)  New Age
(12.)  Oldies
(13.)  Other
(14.)  Pop
(15.)  R&B
(16.)  Rap
(17.)  Reggae
(18.)  Rock
(19.)  Techno
(20.)  Industrial
(21.)  Alternative
(22.)  Ska
(23.)  Death Metal
(24.)  Pranks
(25.)  Soundtrack
(26.)  Euro-Techno
(27.)  Ambient
(28.)  Trip-Hop
(29.)  Vocal
(30.)  Jazz+Funk
(31.)  Fusion
(32.)  Trance
(33.)  Classical
(34.)  Instrumental
(35.)  Acid
(36.)  House
(37.)  Game
(38.)  Sound Clip
(39.)  Gospel
(40.)  Noise
(41.)  AlternRock
(42.)  Bass
(43.)  Soul
(44.)  Punk
(45.)  Space
(46.)  Meditative
(47.)  Instrumental Pop
(48.)  Instrumental Rock
(49.)  Ethnic
(50.)  Gothic
(51.)  Darkwave
(52.)  Techno-Industrial
(53.)  Electronic
(54.)  Pop-Folk
(55.)  Eurodance
(56.)  Dream
(57.)  Southern Rock
(58.)  Comedy
(59.)  Cult
(60.)  Gangsta
(61.)  Top 40
(62.)  Christian Rap
(63.)  Pop/Funk
(64.)  Jungle
(65.)  Native American
(66.)  Cabaret
(67.)  New Wave
(68.)  Psychadelic
(69.)  Rave
(70.)  Showtunes
(71.)  Trailer
(72.)  Lo-Fi
(73.)  Tribal
(74.)  Acid Punk
(75.)  Acid Jazz
(76.)  Polka
(77.)  Retro
(78.)  Musical
(79.)  Rock & Roll
(80.)  Hard Rock
(81.)  Folk
(82.)  Folk/Rock
(83.)  National Folk
(84.)  Swing
(85.)  Fast Fusion
(86.)  Bebob
(87.)  Latin
(88.)  Revival
(89.)  Celtic
(90.)  Bluegrass
(91.)  Avantgarde
(92.)  Gothic Rock
(93.)  Progressive Rock
(94.)  Psychedelic Rock
(95.)  Symphonic Rock
(96.)  Slow Rock
(97.)  Big Band
(98.)  Chorus
(99.)  Easy Listening
(100.)  Acoustic
(101.)  Humour
(102.)  Speech
(103.)  Chanson
(104.)  Opera
(105.)  Chamber Music
(106.)  Sonata
(107.)  Symphony
(108.)  Booty Bass
(109.)  Primus
(110.)  Porn Groove
(111.)  Satire
(112.)  Slow Jam
(113.)  Club
(114.)  Tango
(115.)  Samba
(116.)  Folklore
(117.)  Ballad
(118.)  Power Ballad
(119.)  Rhythmic Soul
(120.)  Freestyle
(121.)  Duet
(122.)  Punk Rock
(123.)  Drum Solo
(124.)  A Capella
(125.)  Euro-House
(126.)  Dance Hall
```

#### iTunes Movie Genre IDs

```sh
AtomicParsley --genre-movie-id-list
```

```text
(4401) Action & Adventure
(4402) Anime
(4403) Classics
(4404) Comedy
(4405) Documentary
(4406) Drama
(4407) Foreign
(4408) Horror
(4409) Independent
(4410) Kids & Family
(4411) Musicals
(4412) Romance
(4413) Sci-Fi & Fantasy
(4414) Short Films
(4415) Special Interest
(4416) Thriller
(4417) Sports
(4418) Western
(4419) Urban
(4420) Holiday
(4421) Made for TV
(4422) Concert Films
(4423) Music Documentaries
(4424) Music Feature Films
(4425) Japanese Cinema
(4426) Jidaigeki
(4427) Tokusatsu
(4428) Korean Cinema
```

#### iTunes TV Genre IDs

```sh
AtomicParsley --genre-tv-id-list
```

```text
(4000) Comedy
(4001) Drama
(4002) Animation
(4003) Action & Adventure
(4004) Classic
(4005) Kids
(4005) Nonfiction
(4007) Reality TV
(4008) Sci-Fi & Fantasy
(4009) Sports
(4010) Teens
(4011) Latino TV
```

### Help

Note: Normally we don't include full help text, but since AtomicParsley has a
long history across various maintainers and repos, we feel it's appropriate to
do so in this case.

```text
AtomicParsley sets metadata into MPEG-4 files & derivatives supporting 3 tag
 schemes: iTunes-style, 3GPP assets & ISO defined copyright notifications.

AtomicParsley quick help for setting iTunes-style metadata into MPEG-4 files.

General usage examples:
  AtomicParsley /path/to.mp4 -T 1
  AtomicParsley /path/to.mp4 -t +
  AtomicParsley /path/to.mp4 --artist "Me" --artwork /path/to/art.jpg
  Atomicparsley /path/to.mp4 --albumArtist "You" --podcastFlag true
  Atomicparsley /path/to.mp4 --stik "TV Show" --advisory explicit

Getting information about the file & tags:
  -T  --test        Test file for mpeg4-ishness & print atom tree
  -t  --textdata    Prints tags embedded within the file
  -E  --extractPix  Extracts pix to the same folder as the mpeg-4 file

Setting iTunes-style metadata tags
  --artist       (string)     Set the artist tag
  --title        (string)     Set the title tag
  --album        (string)     Set the album tag
  --genre        (string)     Genre tag (see --longhelp for more info)
  --tracknum     (num)[/tot]  Track number (or track number/total tracks)
  --disk         (num)[/tot]  Disk number (or disk number/total disks)
  --comment      (string)     Set the comment tag
  --year         (num|UTC)    Year tag (see --longhelp for "Release Date")
  --lyrics       (string)     Set lyrics (not subject to 256 byte limit)
  --lyricsFile   (/path)      Set lyrics to the content of a file
  --composer     (string)     Set the composer tag
  --copyright    (string)     Set the copyright tag
  --grouping     (string)     Set the grouping tag
  --artwork      (/path)      Set a piece of artwork (jpeg or png only)
  --bpm          (number)     Set the tempo/bpm
  --albumArtist  (string)     Set the album artist tag
  --compilation  (boolean)    Set the compilation flag (true or false)
  --hdvideo      (number)     Set the hdvideo flag to one of:
                              false or 0 for standard definition
                              true or 1 for 720p
                              2 for 1080p
  --advisory     (string*)    Content advisory (*values: 'clean', 'explicit')
  --stik         (string*)    Sets the iTunes "stik" atom (see --longhelp)
  --description  (string)     Set the description tag
  --longdesc     (string)     Set the long description tag
  --storedesc    (string)     Set the store description tag
  --TVNetwork    (string)     Set the TV Network name
  --TVShowName   (string)     Set the TV Show name
  --TVEpisode    (string)     Set the TV episode/production code
  --TVSeasonNum  (number)     Set the TV Season number
  --TVEpisodeNum (number)     Set the TV Episode number
  --podcastFlag  (boolean)    Set the podcast flag (true or false)
  --category     (string)     Sets the podcast category
  --keyword      (string)     Sets the podcast keyword
  --podcastURL   (URL)        Set the podcast feed URL
  --podcastGUID  (URL)        Set the episode's URL tag
  --purchaseDate (UTC)        Set time of purchase
  --encodingTool (string)     Set the name of the encoder
  --encodedBy    (string)     Set the name of the Person/company who encoded the file
  --apID         (string)     Set the Account Name
  --cnID         (number)     Set the iTunes Catalog ID (see --longhelp)
  --geID         (number)     Set the iTunes Genre ID (see --longhelp)
  --xID          (string)     Set the vendor-supplied iTunes xID (see --longhelp)
  --gapless      (boolean)    Set the gapless playback flag
  --contentRating (string*)   Set tv/mpaa rating (see -rDNS-help)

Deleting tags
  Set the value to "":        --artist "" --stik "" --bpm ""
  To delete (all) artwork:    --artwork REMOVE_ALL
  manually removal:           --manualAtomRemove "moov.udta.meta.ilst.ATOM"

More detailed iTunes help is available with AtomicParsley --longhelp
Setting reverse DNS forms for iTunes files: see --reverseDNS-help
Setting 3gp assets into 3GPP & derivative files: see --3gp-help
Setting copyright notices for all files: see --ISO-help
For file-level options & padding info: see --file-help
Setting custom private tag extensions: see --uuid-help
Setting ID3 tags onto mpeg-4 files: see --ID3-help

----------------------------------------------------------------------
AtomicParsley version: 20221229.172126.0 d813aa6e0304ed3ab6d92f1ae96cd52b586181ec (utf8)

Submit bug fixes to https://github.com/wez/atomicparsley
```

### `--longhelp`

```text
AtomicParsley help page for setting iTunes-style metadata into MPEG-4 files.
              (3gp help available with AtomicParsley --3gp-help)
          (ISO copyright help available with AtomicParsley --ISO-help)
      (reverse DNS form help available with AtomicParsley --reverseDNS-help)
Usage: AtomicParsley [mp4FILE]... [OPTION]... [ARGUMENT]... [ [OPTION2]...[ARGUMENT2]...]

example: AtomicParsley /path/to.mp4 -e ~/Desktop/pix
example: AtomicParsley /path/to.mp4 --podcastURL "http://www.url.net" --tracknum 45/356
example: AtomicParsley /path/to.mp4 --copyright "℗ © 2006"
example: AtomicParsley /path/to.mp4 --year "2006-07-27T14:00:43Z" --purchaseDate timestamp
example: AtomicParsley /path/to.mp4 --sortOrder artist "Mighty Dub Cats, The
------------------------------------------------------------------------------------------------
  Extract any pictures in user data "covr" atoms to separate files.
  --extractPix       ,  -E                     Extract to same folder (basename derived from file).
  --extractPixToPath ,  -e  (/path/basename)   Extract to specific path (numbers added to basename).
                                                 example: --e ~/Desktop/SomeText
                                                 gives: SomeText_artwork_1.jpg  SomeText_artwork_2.png
                                               Note: extension comes from embedded image file format
------------------------------------------------------------------------------------------------
 Tag setting options:

  --artist           ,  -a   (str)    Set the artist tag: "moov.udta.meta.ilst.©ART.data"
  --title            ,  -s   (str)    Set the title tag: "moov.udta.meta.ilst.©nam.data"
  --album            ,  -b   (str)    Set the album tag: "moov.udta.meta.ilst.©alb.data"
  --genre            ,  -g   (str)    Set the genre tag: "©gen" (custom) or "gnre" (standard).
                                          see the standard list with "AtomicParsley --genre-list"
  --tracknum         ,  -k   (num)[/tot]  Set the track number (or track number & total tracks).
  --disk             ,  -d   (num)[/tot]  Set the disk number (or disk number & total disks).
  --comment          ,  -c   (str)    Set the comment tag: "moov.udta.meta.ilst.©cmt.data"
  --year             ,  -y   (num|UTC)    Set the year tag: "moov.udta.meta.ilst.©day.data"
                                          set with UTC "2006-09-11T09:00:00Z" for Release Date
  --lyrics           ,  -l   (str)    Set the lyrics tag: "moov.udta.meta.ilst.©lyr.data"
  --lyricsFile       ,       (/path)  Set the lyrics tag to the content of a file
  --composer         ,  -w   (str)    Set the composer tag: "moov.udta.meta.ilst.©wrt.data"
  --copyright        ,  -x   (str)    Set the copyright tag: "moov.udta.meta.ilst.cprt.data"
  --grouping         ,  -G   (str)    Set the grouping tag: "moov.udta.meta.ilst.©grp.data"
  --artwork          ,  -A   (/path)  Set a piece of artwork (jpeg or png) on "covr.data"
                                          Note: multiple pieces are allowed with more --artwork args
  --bpm              ,  -B   (num)    Set the tempo/bpm tag: "moov.udta.meta.ilst.tmpo.data"
  --albumArtist      ,  -A   (str)    Set the album artist tag: "moov.udta.meta.ilst.aART.data"
  --compilation      ,  -C   (bool)   Sets the "cpil" atom (true or false to delete the atom)
  --hdvideo          ,  -V   (bool)   Sets the "hdvd" atom (true or false to delete the atom)
  --advisory         ,  -y   (1of3)   Sets the iTunes lyrics advisory ('remove', 'clean', 'explicit')
  --stik             ,  -S   (1of7)   Sets the iTunes "stik" atom (--stik "remove" to delete)
                                           "Movie", "Normal", "TV Show" .... others:
                                           see the full list with "AtomicParsley --stik-list"
                                           or set in an integer value with --stik value=(num)
                                      Note: --stik Audiobook will change file extension to '.m4b'
  --description      ,  -p   (str)    Sets the description on the "desc" atom
  --Rating           ,       (str)    Sets the Rating on the "rate" atom
  --longdesc         ,  -j   (str)    Sets the long description on the "ldes" atom
  --storedesc        ,       (str)    Sets the iTunes store description on the "sdes" atom
  --TVNetwork        ,  -n   (str)    Sets the TV Network name on the "tvnn" atom
  --TVShowName       ,  -H   (str)    Sets the TV Show name on the "tvsh" atom
  --TVEpisode        ,  -I   (str)    Sets the TV Episode on "tven":"209", but it is a string: "209 Part 1"
  --TVSeasonNum      ,  -U   (num)    Sets the TV Season number on the "tvsn" atom
  --TVEpisodeNum     ,  -N   (num)    Sets the TV Episode number on the "tves" atom
  --podcastFlag      ,  -f   (bool)   Sets the podcast flag (values are "true" or "false")
  --category         ,  -q   (str)    Sets the podcast category; typically a duplicate of its genre
  --keyword          ,  -K   (str)    Sets the podcast keyword; invisible to MacOSX Spotlight
  --podcastURL       ,  -L   (URL)    Set the podcast feed URL on the "purl" atom
  --podcastGUID      ,  -J   (URL)    Set the episode's URL tag on the "egid" atom
  --purchaseDate     ,  -D   (UTC)    Set Universal Coordinated Time of purchase on a "purd" atom
                                       (use "timestamp" to set UTC to now; can be akin to id3v2 TDTG tag)
  --encodingTool     ,       (str)    Set the name of the encoder on the "©too" atom
  --encodedBy        ,       (str)    Set the name of the Person/company who encoded the file on the "©enc" atom
  --apID             ,  -Y   (str)    Set the name of the Account Name on the "apID" atom
  --cnID             ,       (num)    Set iTunes Catalog ID, used for combining SD and HD encodes in iTunes on the "cnID" atom

                                      To combine you must set "hdvd" atom on one file and must have same "stik" on both file
                                      Must not use "stik" of value Home Video(0), use Movie(9)

                                      iTunes Catalog numbers can be obtained by finding the item in the iTunes Store.  Once item
                                      is found in the iTunes Store right click on picture of item and select copy link.  Paste this link
                                      into a document or web browser to display the catalog number ID.

                                      An example link for the video Street Kings is:
                                      http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=278743714&s=143441
                                      Here you can see the cnID is 278743714

                                      Alternatively you can use iMDB numbers, however these will not match the iTunes catalog.

  --geID             ,       (num)    Set iTunes Genre ID.  This does not necessarily have to match genre.
                                      See --genre-movie-id-list and --genre-tv-id-list

  --xID              ,       (str)    Set iTunes vendor-supplied xID, used to allow iTunes LPs and iTunes Extras to interact
                                            with other content in your iTunes Library
  --gapless          ,       (bool)   Sets the gapless playback flag for a track in a gapless album
  --sortOrder    (type)      (str)    Sets the sort order string for that type of tag.
                                       (available types are: "name", "artist", "albumartist",
                                        "album", "composer", "show")

NOTE: Except for artwork, only 1 of each tag is allowed; artwork allows multiple pieces.
NOTE: Tags that carry text(str) have a limit of 255 utf8 characters;
however lyrics and long descriptions have no limit.
------------------------------------------------------------------------------------------------
 To delete a single atom, set the tag to null (except artwork):
  --artist "" --lyrics ""
  --artwork REMOVE_ALL
  --metaEnema        ,  -P            Douches away every atom under "moov.udta.meta.ilst"
  --foobar2000Enema  ,  -2            Eliminates foobar2000's non-compliant so-out-o-spec tagging scheme
  --manualAtomRemove "some.atom.path" where some.atom.path can be:
      keys to using manualAtomRemove:
         ilst.ATOM.data or ilst.ATOM target an iTunes-style metadata tag
         ATOM:lang=foo               target an atom with this language setting; like 3gp assets
         ATOM.----.name:[foo]        target a reverseDNS metadata tag; like iTunNORM
                                     Note: these atoms show up with 'AP -t' as: Atom "----" [foo]
                                         'foo' is actually carried on the 'name' atom
         ATOM[x]                     target an atom with an index other than 1; like trak[2]
         ATOM.uuid=hex-hex-hex-hex   targt a uuid atom with the uuid of hex string representation
    examples:
        moov.udta.meta.ilst.----.name:[iTunNORM]      moov.trak[3].cprt:lang=urd
        moov.trak[2].uuid=55534d54-21d2-4fce-bb88-695cfac9c740
------------------------------------------------------------------------------------------------
                   Environmental Variables (affecting picture placement) (macOS ONLY)

  set PIC_OPTIONS in your shell to set these flags; preferences are separated by colons (:)

 MaxDimensions=num (default: 0; unlimited); sets maximum pixel dimensions
 DPI=num           (default: 72); sets dpi
 MaxKBytes=num     (default: 0; unlimited);  maximum kilobytes for file (jpeg only)
 AddBothPix=bool   (default: false); add original & converted pic (for archival purposes)
 AllPixJPEG | AllPixPNG =bool (default: false); force conversion to a specific picture format
 SquareUp          (include to square images to largest dimension, allows an [ugly] 160x1200->1200x1200)
 removeTempPix     (include to delete temp pic files created when resizing images after tagging)
 ForceHeight=num   (must also specify width, below) force image pixel height
 ForceWidth=num    (must also specify height, above) force image pixel width

 Examples: (bash-style)
 export PIC_OPTIONS="MaxDimensions=400:DPI=72:MaxKBytes=100:AddBothPix=true:AllPixJPEG=true"
 export PIC_OPTIONS="SquareUp:removeTempPix"
 export PIC_OPTIONS="ForceHeight=999:ForceWidth=333:removeTempPix"
------------------------------------------------------------------------------------------------
```

```

```
