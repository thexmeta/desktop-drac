import { describe, it } from 'node:test'
import assert from 'node:assert'
import {
  formatPathForFlatpak,
  formatWorkingDirectoryForFlatpak,
} from '../../src/lib/editors/launch'
import { Shell } from '../../src/lib/shells/linux'

// Port of the retired app/test/unit/helpers/linux-test.ts (T11). The helper
// app/src/lib/helpers/linux.ts was retired in favor of upstream's native
// path-exists; the fork-only flatpak spawn formatting now lives in
// editors/launch.ts and the Black Box shell in shells/linux.ts.
describe('flatpak editor path formatting (preserved from retired helpers/linux.ts)', () => {
  if (__LINUX__) {
    it('strips the /var/lib/flatpak/app prefix for flatpak-spawn --host args', () => {
      const path =
        '/var/lib/flatpak/app/com.visualstudio.code/current/active/export/bin/com.visualstudio.code'
      assert.strictEqual(
        formatPathForFlatpak(path),
        'com.visualstudio.code/current/active/export/bin/com.visualstudio.code'
      )
    })

    it('preserves non-flatpak editor paths', () => {
      const path = '/usr/bin/subl'
      assert.strictEqual(formatPathForFlatpak(path), path)
    })

    it('normalizes whitespace in the working directory for flatpak-spawn', () => {
      const path = '/home/test/path with space'
      assert.strictEqual(
        formatWorkingDirectoryForFlatpak(path),
        '/home/test/path with space'
      )
    })

    it('returns a working directory without spaces unchanged', () => {
      const path = '/home/test/path_without_spaces'
      assert.strictEqual(formatWorkingDirectoryForFlatpak(path), path)
    })
  }
})

// Regression guard: the upstream merge that resolved shells/linux.ts silently
// dropped the fork's Black Box shell (baseline 1b). This must not recur.
describe('Black Box shell (preserved fork-only shell, baseline 1b)', () => {
  it('is a known Linux shell option', () => {
    assert.strictEqual(Shell.BlackBox, 'Black Box')
  })
})
