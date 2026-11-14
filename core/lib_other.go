//go:build !android && cgo

package main

func nextHandle(action *Action, result ActionResult) bool {
	return false
}

// delayDataPlaneReady: desktop platforms have no app-managed TUN gate
// (the kernel owns its listener), so URLTest results are always
// reportable, exactly as before (T89 D-08 is Android-specific).
func delayDataPlaneReady() bool {
	return true
}
func purgeNativeMemory() {}
