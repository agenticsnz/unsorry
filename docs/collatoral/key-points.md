# unsorry - Key Points
[Home](/) | [Executive Summary](/docs/collatoral/summary.html)

## Summary
This project explores the development of autonomous, agentic systems capable of executing complex, multi-step engineering and research tasks through iterative, self-correcting loops. Unsorry is a crowdsourced, distributed platform that leverages LLMs and GitHub-based infrastructure to solve formal mathematical proofs in Lean. By utilizing a "loop" methodology—where agents create, verify, and refine artifacts—the project demonstrates how decentralized AI swarms can achieve high-volume productivity and collaborative research, effectively creating a modern, AI-driven equivalent to the SETI@home distributed computing model.

## Key Concepts & Insights

### The "unsorry" Platform: Distributed Mathematical Research
The project "unsorry" applies agentic loops to formal mathematics using the Lean theorem prover.
*   **Infrastructure:** The system uses Git and GitHub Actions as the coordination layer, allowing for a decentralized, serverless swarm of agents to work on proofs asynchronously.
*   **Symbolic Specification (AISP):** The project utilizes AISP, a symbolic mathematical protocol that LLMs can interpret natively to perform verification without extensive prior training.
*   **Scalability:** By treating pull requests as the primary mechanism for coordinating work, the system successfully managed over 1,400 merged pull requests and 7,500 total commits within 10 days.
*   **Resilience:** The system is designed to be self-healing; when the pipeline encounters bottlenecks or errors, agents are tasked with creating "bypass" pull requests to fix the infrastructure itself.

### The Role of Model Sophistication
*   **Step-Change Improvements:** The presenters noted that newer models (such as the experimental "Fable") represent a significant leap in capability, specifically in their ability to manage broader context and utilize workflows without excessive hand-holding.
*   **Prompting Philosophy:** A key insight is the shift from "micromanaging" agents to providing high-level goals and "getting out of the way." Over-structuring system prompts can sometimes hamstring a highly capable model.
*   **Memory Management:** A recurring challenge is the accumulation of "silent memory," where agents become bogged down by past, potentially irrelevant, data. The team is developing methods to prune these memories to maintain agent focus.

## Actionable Takeaways

*   **Ground Agents in Business Principles:** To prevent agents from "over-engineering" or focusing on trivial technical tasks, ground their decision-making in customer-centric principles (e.g., "focus on user experience" or "improve net promoter score").
*   **Leverage Git as a Coordination Layer:** For distributed AI projects, use existing version control systems (like Git) as a decentralized, persistent state machine. This allows multiple agents to collaborate on complex tasks without needing a centralized, monolithic orchestrator.
*   **Prioritize "Lean" Verification:** For research-heavy tasks, utilize formal verification languages like Lean. This ensures that the output is mathematically sound, transforming the AI's role from a "generator" to a "proven solver."
*   **Monitor Infrastructure Costs:** Be aware that high-frequency agentic loops can lead to significant CI/CD usage costs. Implement "sovereign engines" or fair-queuing mechanisms to manage token consumption and prevent system exhaustion.
