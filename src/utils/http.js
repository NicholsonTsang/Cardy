import axios from 'axios'
import { supabase } from '@/lib/supabase'

// Create axios instance with default configuration
const httpClient = axios.create({
  timeout: 30000, // 30 seconds timeout
  headers: {
    'Content-Type': 'application/json',
  }
})

// Request interceptor for logging
httpClient.interceptors.request.use(
  (config) => {
    console.log(`Making ${config.method?.toUpperCase()} request to:`, config.url)
    return config
  },
  (error) => {
    console.error('Request interceptor error:', error)
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
httpClient.interceptors.response.use(
  (response) => {
    console.log(`Response received from ${response.config.url}:`, response.status)
    return response
  },
  (error) => {
    console.error('HTTP Error:', {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
      message: error.message
    })
    
    // Handle specific error cases
    if (error.code === 'ECONNABORTED') {
      error.message = 'Request timeout - please try again'
    } else if (error.response?.status === 429) {
      error.message = 'Rate limit exceeded - please wait and try again'
    } else if (error.response?.status >= 500) {
      error.message = 'Server error - please try again later'
    }
    
    return Promise.reject(error)
  }
)

// OpenAI Realtime API specific function - uses Supabase proxy to avoid CORS
export const sendOpenAIRealtimeRequest = async (model, sdpOffer, ephemeralToken, instructions = '') => {
  try {
    console.log(`Sending SDP offer to OpenAI Realtime API via Supabase proxy...`)
    
    // Use Supabase function as proxy to avoid CORS issues
    const { data, error } = await supabase.functions.invoke('openai-realtime-proxy', {
      body: {
        model: model,
        sdpOffer: sdpOffer,
        ephemeralToken: ephemeralToken,
        instructions: instructions // Pass the complete instructions from client
      }
    })

    if (error) {
      console.error('Supabase function error:', error)
      throw new Error(error.message || 'Supabase function call failed')
    }
    
    console.log('OpenAI Realtime API response received successfully via proxy')
    console.log('Raw Supabase function response:', data)
    console.log('SDP Answer type:', typeof data.sdpAnswer)
    console.log('SDP Answer length:', data.sdpAnswer?.length)
    console.log('SDP Answer preview:', data.sdpAnswer?.substring(0, 100))
    
    // The proxy returns the SDP answer and passes through the instructions
    return {
      success: true,
      data: data.sdpAnswer,
      instructions: data.instructions, // Instructions passed through from client
      status: 200
    }
    
  } catch (error) {
    console.error('OpenAI Realtime API request failed:', error)
    
    // Enhanced error handling for OpenAI API via proxy
    let errorMessage = 'Failed to connect to OpenAI Realtime API'
    
    if (error.message) {
      errorMessage = error.message
    } else if (error.response) {
      // Server responded with error status
      const status = error.response.status
      const data = error.response.data
      
      switch (status) {
        case 400:
          errorMessage = data?.error || 'Invalid request - check your parameters'
          break
        case 401:
          errorMessage = 'Authentication failed - check your API key'
          break
        case 403:
          errorMessage = 'Access forbidden - check your permissions'
          break
        case 429:
          errorMessage = 'Rate limit exceeded - please wait and try again'
          break
        case 500:
        case 502:
        case 503:
          errorMessage = data?.error || 'OpenAI service temporarily unavailable'
          break
        default:
          errorMessage = data?.error || `OpenAI API error (${status}): ${error.message}`
      }
    } else if (error.request) {
      // Request was made but no response received
      if (error.code === 'ECONNABORTED') {
        errorMessage = 'Connection timeout - please check your internet connection'
      } else if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
        errorMessage = 'Cannot reach Supabase proxy - please check your connection'
      } else {
        errorMessage = 'Network error - please try again'
      }
    }
    
    return {
      success: false,
      error: errorMessage,
      details: error.message,
      status: error.response?.status
    }
  }
}

// Generic HTTP methods
export const get = (url, config = {}) => httpClient.get(url, config)
export const post = (url, data, config = {}) => httpClient.post(url, data, config)
export const put = (url, data, config = {}) => httpClient.put(url, data, config)
export const del = (url, config = {}) => httpClient.delete(url, config)
export const patch = (url, data, config = {}) => httpClient.patch(url, data, config)

// Export the configured axios instance for advanced usage
export default httpClient 