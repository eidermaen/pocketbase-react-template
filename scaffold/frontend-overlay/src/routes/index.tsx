import { createFileRoute, Link } from "@tanstack/react-router";
import { useCurrentUser } from "@/hooks/useCurrentUser";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/")({
	component: LandingPage
});

function LandingPage() {
	const { user } = useCurrentUser();

	return (
		<div className="flex min-h-screen flex-col items-center justify-center gap-6 px-4 text-center">
			<h1 className="text-4xl font-bold">Your app, ready to go</h1>
			<p className="max-w-md text-muted-foreground">
				PocketBase + React, wired up with routing, auth, and a starting point for everything else.
			</p>
			<Button asChild>
				<Link to={user ? "/dashboard" : "/login"}>{user ? "Go to dashboard" : "Sign in"}</Link>
			</Button>
		</div>
	);
}
