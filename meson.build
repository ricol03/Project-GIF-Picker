project('io.ricol03.gifpicker', 'c', 'vala')

gnome = import('gnome')

if host_machine.system() == 'windows'
  add_project_link_arguments('-lshell32', language: 'c')
  add_project_link_arguments('-luser32', language: 'c')
  add_project_link_arguments('-lkernel32', language: 'c')
endif

inc = include_directories('src')

project_gif_picker_sources = [
	'src' / 'Application.vala',
	'src' / 'About.vala',
    'src' / 'Dialogs.vala',
    'src' / 'Files.vala',
    'src' / 'Gif.vala',
    #'src' / 'GlobalShortcut.vala',
    'src' / 'Logs.vala',
    'src' / 'Main.vala',
    #'src' / 'Tray.vala',
    'src' / 'Settings.vala',
    'src' / 'Window.vala',
]

if host_machine.system() == 'windows'
	project_gif_picker_sources += files('src/windows/WinClipboard.c')
	add_project_arguments('-D', 'WINDOWS', language: 'vala')
endif

gresource = gnome.compile_resources(
    'gresource',
    'data' / 'gresource.xml',
    source_dir: 'data'
)

install_data(
    'data' / 'io.ricol03.gifpicker.desktop',
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
        #dependency('gtk4-wayland'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        #dependency('libportal')
    ],
    include_directories: inc,
    install: true
)


