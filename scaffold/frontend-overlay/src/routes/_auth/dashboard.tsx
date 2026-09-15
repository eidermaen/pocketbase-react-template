import { createFileRoute } from "@tanstack/react-router";
import { useCurrentUser } from "@/hooks/useCurrentUser";

export const Route = createFileRoute("/_auth/dashboard")({
	component: DashboardPage
});

function DashboardPage() {
	const { user } = useCurrentUser();

	return (
		<div className="space-y-2">
			<h1 className="text-2xl font-semibold">Dashboard</h1>
			<p className="text-muted-foreground">Signed in as {user?.email}</p>
		</div>
	);
}
