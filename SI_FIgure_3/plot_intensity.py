import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import matplotlib as mpl

mpl.rcParams.update({
    "font.family": "sans-serif", "font.sans-serif": ["Arial", "Helvetica"],
    "font.size": 11, "axes.labelsize": 13, "axes.titlesize": 15, "legend.fontsize": 10,
    "mathtext.fontset": "stixsans",
    "xtick.direction": "in", "ytick.direction": "in",
    "xtick.major.width": 1.1, "ytick.major.width": 1.1,
    "xtick.minor.width": 0.8, "ytick.minor.width": 0.8,
    "xtick.major.size": 6,   "ytick.major.size": 6,
    "xtick.minor.size": 3,   "ytick.minor.size": 3,
    "axes.linewidth": 1.1,
    "figure.dpi": 200,
    "savefig.dpi": 900,
    "savefig.bbox": "tight",
    "savefig.pad_inches": 0.02,
    "savefig.transparent": False,
    "pdf.fonttype": 42, "ps.fonttype": 42, "svg.fonttype": "none",
    "path.simplify": True, "path.simplify_threshold": 0.0,
})
mpl.rcParams.update({"xtick.labelsize": 14, "ytick.labelsize": 14})

# ── Load data ─────────────────────────────────────────────────────────

frozen = 'Intensity_Values_frozen.csv'
vitrified = 'Intensity_Values_vitrified.csv'

intensity_frozen = pd.read_csv(frozen)
intensity_vitrified = pd.read_csv(vitrified)

# ── Plotting intensity data (Column 'Mean') vs time (Column 'Slice')─────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(6, 4.5))

# Plot intensity data vs time 
ax.plot(intensity_frozen['Slice'], intensity_frozen['Mean'], 
        label='Frozen', linewidth=1.4, color='tab:blue')
ax.plot(intensity_vitrified['Slice'], intensity_vitrified['Mean'], 
        label='Vitrified', linewidth=1.4, color='tab:orange')

ax.set_xlabel('Time Frame')
ax.set_ylabel('Intensity')
ax.set_xlim(left=0)
ax.grid(True, alpha=0.3, linestyle='--', linewidth=0.8)

leg = ax.legend(fontsize=10, loc='best', frameon=True, framealpha=0.95, 
                borderpad=0.6, handlelength=1.4, handletextpad=0.6, 
                borderaxespad=0.8)
leg.get_frame().set_linewidth(0.8)

fig.tight_layout()

# ── Save PNG Figures ────────────────────────────────────────
fig.savefig("intensity_data.png") 
plt.show()
