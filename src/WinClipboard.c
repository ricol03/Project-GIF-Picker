#include <stdio.h>
#include <windows.h>
#include <shlobj.h>

__attribute__((visibility("default")))
int setWindowsClipboard(const char * filepath) {
    if (!filepath)
		return -1;

    int wlen = MultiByteToWideChar(CP_UTF8, 0, filepath, -1, NULL, 0);
    if (wlen <= 0)
		return -2;

    wchar_t *wpath = malloc(wlen * sizeof(wchar_t));
    if (!wpath)
		return -3;

    if (!MultiByteToWideChar(CP_UTF8, 0, filepath, -1, wpath, wlen)) {
        free(wpath);
        return -4;
    }

    SIZE_T size = sizeof(DROPFILES) + (wlen + 1) * sizeof(wchar_t);

    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, size);
    if (!hMem) {
        free(wpath);
        return -5;
    }

    DROPFILES *df = (DROPFILES *)GlobalLock(hMem);
    if (!df) {
        free(wpath);
        GlobalFree(hMem);
        return -6;
    }

    df->pFiles = sizeof(DROPFILES);
    df->fWide = TRUE;

    wchar_t *dest = (wchar_t *)((BYTE *)df + sizeof(DROPFILES));
    memcpy(dest, wpath, wlen * sizeof(wchar_t));
    dest[wlen] = L'\0';

    GlobalUnlock(hMem);
    free(wpath);

    if (!OpenClipboard(GetForegroundWindow()))
		return -7;

	EmptyClipboard();

    if (!SetClipboardData(CF_HDROP, hMem)) {
        CloseClipboard();
        return -8;
    }

    CloseClipboard();
    return 1;
}