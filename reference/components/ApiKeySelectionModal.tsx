
import React from 'react';
import { X, KeyRound, ExternalLink } from 'lucide-react';

interface ApiKeySelectionModalProps {
  onSelectKey: () => void;
}

const ApiKeySelectionModal: React.FC<ApiKeySelectionModalProps> = ({ onSelectKey }) => {
  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center p-4 bg-slate-900/70 backdrop-blur-md animate-in fade-in duration-300">
      <div className="bg-white rounded-[2.5rem] shadow-2xl w-full max-w-lg overflow-hidden animate-in zoom-in-95 duration-300">
        <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-red-50/20">
          <div className="flex items-center gap-3">
            <div className="bg-red-500 text-white p-3 rounded-xl shadow-lg shadow-red-100">
              <KeyRound className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-red-900 tracking-tight">API Key Required</h3>
          </div>
          {/* No close button as user must select a key to proceed */}
        </div>
        
        <div className="p-8 space-y-6 text-center">
          <p className="text-slate-700 text-base leading-relaxed font-medium">
            To use the advanced AI features (like match summaries and venue intelligence),
            you need to select a paid API key for the Gemini API.
          </p>
          <p className="text-slate-600 text-sm font-medium">
            This ensures access to the models and tools required for these features.
          </p>

          <button 
            type="button"
            onClick={onSelectKey}
            className="w-full bg-blue-600 text-white rounded-2xl py-4 font-black shadow-xl shadow-blue-100 hover:bg-blue-700 transition-all flex items-center justify-center gap-3 uppercase tracking-widest text-sm"
          >
            <KeyRound className="w-5 h-5" />
            Select Your API Key
          </button>

          <a 
            href="https://ai.google.dev/gemini-api/docs/billing" 
            target="_blank" 
            rel="noopener noreferrer" 
            className="inline-flex items-center gap-2 text-blue-600 font-bold text-sm hover:underline mt-4"
          >
            <ExternalLink className="w-4 h-4" />
            Learn about Gemini API billing
          </a>
        </div>
      </div>
    </div>
  );
};

export default ApiKeySelectionModal;
