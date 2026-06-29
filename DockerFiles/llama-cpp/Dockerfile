FROM ghcr.io/ggml-org/llama.cpp:server

# Install curl
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download the model directly inside the image using curl
RUN mkdir -p /models && \
    curl -L "https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/main/embeddinggemma-300M-Q8_0.gguf" -o /models/embeddinggemma-300M-Q8_0.gguf

# Expose server port
EXPOSE 8080
