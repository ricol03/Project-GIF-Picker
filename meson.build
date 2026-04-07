project('io.ricol03.gif-picker',
    'vala', 'c'
)

gnome = import('gnome')

project_gif_picker_sources = [
	'src' / 'Application.vala',
	'src' / 'About.vala',
    'src' / 'Dialogs.vala',
    'src' / 'Files.vala',
    'src' / 'Gif.vala',
    'src' / 'GlobalShortcut.vala',
    'src' / 'Main.vala',
    'src' / 'Tray.vala',
    'src' / 'Settings.vala',
    'src' / 'Window.vala',
]

gresource = gnome.compile_resources(
    'gresource',
    'data' / 'gresource.xml',
    source_dir: 'data'
)

install_data(
    'data' / 'io.ricol03.gif-picker.desktop',
    install_dir: get_option('datadir') / 'applications'
)

install_data(
  	'data' / 'gifpicker-small.svg',
	install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps'
)

executable(
    meson.project_name(),
    project_gif_picker_sources,
    gresource,
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-wayland'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        #dependency('libportal')
    ],
    install: true
)


