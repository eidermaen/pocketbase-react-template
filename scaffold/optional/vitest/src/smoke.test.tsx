import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { Button } from "@/components/ui/button";

// Proves the Vitest + Testing Library + jsdom + Tailwind/shadcn pipeline is
// wired up correctly. Replace with real tests as the app grows.
describe("Button", () => {
	it("renders its children", () => {
		render(<Button>Click me</Button>);
		expect(screen.getByRole("button", { name: "Click me" })).toBeInTheDocument();
	});
});
