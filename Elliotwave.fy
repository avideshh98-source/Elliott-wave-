import streamlit as st
import requests
import pandas as pd
import numpy as np
import plotly.graph_objects as go

st.title("📊 Elliott Wave AI Analyzer (Advanced v1)")

coin = st.text_input("Enter coin (bitcoin, ethereum, solana)", "bitcoin")


# ---------------- PRICE DATA ----------------
def get_data(coin):
    url = f"https://api.coingecko.com/api/v3/coins/{coin}/market_chart?vs_currency=usd&days=7"
    r = requests.get(url)
    data = r.json()

    if "prices" not in data:
        return None

    df = pd.DataFrame(data["prices"], columns=["time", "price"])
    df["time"] = pd.to_datetime(df["time"], unit="ms")

    return df


# ---------------- SWING DETECTION ----------------
def detect_swings(df, window=5):
    highs = []
    lows = []

    prices = df["price"].values

    for i in range(window, len(prices) - window):
        segment = prices[i - window:i + window]

        if prices[i] == max(segment):
            highs.append((i, prices[i]))

        if prices[i] == min(segment):
            lows.append((i, prices[i]))

    return highs, lows


# ---------------- WAVE BUILDING ----------------
def build_waves(swings):
    waves = []

    for i in range(min(len(swings), 5)):
        waves.append(swings[i])

    return waves


# ---------------- PLOT ----------------
def plot_chart(df, highs, lows, waves):
    fig = go.Figure()

    fig.add_trace(go.Scatter(
        x=df["time"],
        y=df["price"],
        mode="lines",
        name="Price"
    ))

    # Highs
    if highs:
        hx = [df["time"].iloc[i] for i, _ in highs]
        hy = [p for _, p in highs]

        fig.add_trace(go.Scatter(
            x=hx,
            y=hy,
            mode="markers+lines",
            name="High Swings"
        ))

    # Lows
    if lows:
        lx = [df["time"].iloc[i] for i, _ in lows]
        ly = [p for _, p in lows]

        fig.add_trace(go.Scatter(
            x=lx,
            y=ly,
            mode="markers+lines",
            name="Low Swings"
        ))

    fig.update_layout(title="Elliott Wave Structure (Approx)", height=600)

    st.plotly_chart(fig)


# ---------------- MAIN ----------------
if st.button("Analyze Elliott Wave"):

    df = get_data(coin)

    if df is None:
        st.error("Failed to load data")
        st.stop()

    highs, lows = detect_swings(df)

    waves = build_waves(highs + lows)

    st.subheader("📊 Market Data")
    st.write(df.tail())

    st.subheader("📈 Detected Swings")
    st.write("Highs:", len(highs))
    st.write("Lows:", len(lows))

    st.subheader("🧠 Wave Analysis (Basic)")
    st.write("Possible wave points:", waves)

    st.subheader("📉 Chart")
    plot_chart(df, highs, lows, waves)
