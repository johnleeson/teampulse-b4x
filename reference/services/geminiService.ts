import { GoogleGenAI } from "@google/genai";
import { FeedEvent, Match } from "../types";

// Helper to get fresh Gemini instance for each call, ensuring it uses the latest API key
const getAI = () => new GoogleGenAI({ apiKey: process.env.API_KEY });

const QUOTA_ERROR_MESSAGE_SUFFIX = "Please check your plan and billing details for the Gemini API at https://ai.google.dev/gemini-api/docs/rate-limits or monitor your usage at https://ai.dev/rate-limit.";

export interface MatchIntel {
  weather: string;
  locationDetails: string;
  mapUrl?: string;
  links: { title: string, uri: string }[];
}

export async function getMatchIntel(
  location: string, 
  date: string, 
  time: string
): Promise<MatchIntel> {
  const ai = getAI();
  
  const prompt = `Provide the following details for the sports venue "${location}" on ${date} at approximately ${time}:
  1. Use Google Maps to find the official location URI and confirmed address.
  2. Use Google Search to find the weather forecast for this specific location and date.
  
  Summarize the weather and venue details briefly.`;

  try {
    const response = await ai.models.generateContent({
      // Updated to gemini-2.5-flash as it is the recommended model for Google Maps grounding
      model: "gemini-2.5-flash", 
      contents: prompt,
      config: {
        tools: [{ googleSearch: {} }, { googleMaps: {} }],
      },
    });

    const text = response.text || "Retrieving venue intelligence...";
    const groundingChunks = response.candidates?.[0]?.groundingMetadata?.groundingChunks || [];
    
    const links: { title: string, uri: string }[] = [];
    let mapUrl: string | undefined = undefined;

    groundingChunks.forEach((chunk: any) => {
      if (chunk.maps) {
        const uri = chunk.maps.uri;
        const title = chunk.maps.title || "Venue Location";
        links.push({ title, uri });
        if (!mapUrl) mapUrl = uri;
      } 
      else if (chunk.web) {
        const uri = chunk.web.uri;
        const title = chunk.web.title || "Location Reference";
        links.push({ title, uri });
        if (!mapUrl && (uri.includes('google.com/maps') || uri.includes('maps.app.goo.gl'))) {
          mapUrl = uri;
        }
      }
    });

    const lines = text.split('\n').filter(l => l.trim().length > 0);
    const weatherLine = lines.find(l => /weather|forecast|temp|degrees|sky|rain|sun/i.test(l)) || lines[0] || "Forecast unavailable";

    return {
      weather: weatherLine,
      locationDetails: text,
      mapUrl: mapUrl,
      links: links
    };
  } catch (error: any) {
    console.error("Gemini Match Intel API Error:", error);
    const errorMessage = typeof error === 'object' && error !== null && 'message' in error ? error.message : String(error);
    
    if (errorMessage.includes("Requested entity was not found")) {
      throw error;
    }

    if (errorMessage.includes("RESOURCE_EXHAUSTED") || errorMessage.includes("quota")) {
      const quotaMessage = `API quota exceeded. ${QUOTA_ERROR_MESSAGE_SUFFIX}`;
      return {
        weather: `Weather data unavailable. ${quotaMessage}`,
        locationDetails: `Detailed intelligence for this venue location could not be retrieved. ${quotaMessage}`,
        links: []
      };
    }
    return {
      weather: "Weather forecast currently unavailable due to an API error.",
      locationDetails: "Detailed intelligence for this venue location could not be retrieved due to an API error.",
      links: []
    };
  }
}

export async function generateMatchSummary(match: Match, events: FeedEvent[]): Promise<string> {
  const ai = getAI();
  const eventTimeline = events
    .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime())
    .map(e => `[${e.type}] ${e.content}`)
    .join('\n');

  const prompt = `Write a professional club match report suitable for a season booklet for the following match:
  Title: ${match.title}
  Opponent: ${match.opponentName || 'Opposition'}
  Final Score: ${match.scoreA} - ${match.scoreB}
  Location: ${match.location}
  Date: ${match.date}
  
  Timeline of events:
  ${eventTimeline}
  
  Write in a warm, club-magazine style. Cover the flow of the game, key scorers/moments from the timeline, and the final result. Keep it under 300 words. Do not invent events that are not in the timeline.`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview", // Best for Basic Text Tasks
      contents: prompt,
    });

    return response.text || "No summary could be generated for this match.";
  } catch (error: any) {
    console.error("Gemini Match Summary API Error:", error);
    const errorMessage = typeof error === 'object' && error !== null && 'message' in error ? error.message : String(error);
    
    if (errorMessage.includes("Requested entity was not found")) {
      throw error;
    }
    
    return "An error occurred while generating the match report. Please try again later.";
  }
}