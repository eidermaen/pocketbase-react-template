import { useCallback, useSyncExternalStore } from "react";
import type { AuthRecord } from "pocketbase";
import { pb } from "@/lib/pb";

function subscribe(callback: () => void) {
	return pb.authStore.onChange(callback);
}

function getSnapshot(): AuthRecord {
	return pb.authStore.record;
}

// Mirrors pb.authStore's current state; does not perform any navigation.
// Route `beforeLoad` guards own redirect decisions (see routes/_auth/route.tsx
// and routes/login.tsx) so auth state changes and navigation stay decoupled.
export function useCurrentUser() {
	const user = useSyncExternalStore(subscribe, getSnapshot);

	const login = useCallback((email: string, password: string) => {
		return pb.collection("users").authWithPassword(email, password);
	}, []);

	const logout = useCallback(() => {
		pb.authStore.clear();
	}, []);

	return { user, login, logout };
}
