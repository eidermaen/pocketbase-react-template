import { createFileRoute, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { pb } from "@/lib/pb";
import { useCurrentUser } from "@/hooks/useCurrentUser";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/_auth")({
	// This is the only route that decides "not logged in -> kick to login".
	beforeLoad: ({ location }) => {
		if (!pb.authStore.isValid) {
			throw redirect({
				to: "/login",
				search: { redirect: location.href }
			});
		}
	},
	component: AuthLayout
});

function AuthLayout() {
	const { logout } = useCurrentUser();
	const navigate = useNavigate();

	function handleLogout() {
		logout();
		navigate({ to: "/login" });
	}

	return (
		<div className="min-h-screen">
			<header className="flex items-center justify-between border-b p-4">
				<span className="font-semibold">My App</span>
				<Button variant="outline" size="sm" onClick={handleLogout}>
					Log out
				</Button>
			</header>
			<main className="p-4">
				<Outlet />
			</main>
		</div>
	);
}
