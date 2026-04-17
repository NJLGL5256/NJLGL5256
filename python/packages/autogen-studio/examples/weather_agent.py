"""Streaming weather-agent example with credential preloading.

Run with:

    python -m examples.weather_agent

from python/packages/autogen-studio
"""

from __future__ import annotations

from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import OpenAIChatCompletionClient

from autogen_studio.credential_loader import load_api_key


async def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    return f"The weather in {city} is 73 degrees and Sunny."


async def main() -> None:
    api_key = load_api_key("OPENAI_API_KEY")

    model_client = OpenAIChatCompletionClient(
        model="gpt-4o",
        api_key=api_key,
    )

    agent = AssistantAgent(
        name="weather_agent",
        model_client=model_client,
        tools=[get_weather],
        system_message="You are a helpful assistant.",
        reflect_on_tool_use=True,
        model_client_stream=True,
    )

    await Console(agent.run_stream(task="What is the weather in New York?"))
    await model_client.close()


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
