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
    'src' / 'Window.vala',
]

gres = files('src/project-gif-picker.gresource.xml')

project_gif_picker_sources += gnome.compile_resources('project-gif-picker-resources',
  gres
)

executable(
    meson.project_name(),
    project_gif_picker_sources,
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-wayland'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('libportal')
    ],
    install: true
)


install_data(
    'data' / 'io.ricol03.gif-picker.desktop',
    install_dir: get_option('datadir') / 'applications'
)
