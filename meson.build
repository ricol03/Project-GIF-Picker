project('io.ricol03.gifpicker',
    'vala', 'c'
)

gnome = import('gnome')

project_gif_picker_sources = [
	'src' / 'Application.vala',
    'src' / 'Dialogs.vala',
    'src' / 'Files.vala',
    'src' / 'Gif.vala',
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
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
    ],
    install: true
)


install_data(
    'data' / 'gif-picker.desktop',
    install_dir: get_option('datadir') / 'applications'
)
