# pip install psychopy ffpyplayer
from psychopy import visual, core, prefs
from psychopy.hardware import keyboard
from PIL import Image
from datetime import datetime
import csv, os, time, random
import numpy as np
import imageio

# ------------- CONFIG -------------
parent_folder = r"C:\Users\y50046154\Projects\res-classifier\data\sample_videos"
prefs.general['movieLib'] = ['opencv', 'ffpyplayer', 'moviepy']
RESPONSE_KEYS = ["left", "right", "escape", "backspace"]  # add replay keys


TRIALS = [
    {"reference": f"{parent_folder}/BurnedTrees-1_gt_part2.mp4",
     "test":      f"{parent_folder}/BurnedTrees-1_normal_part2.mp4"},
    # {"reference": f"{parent_folder}/BurnedTrees-1_gt_part2.mp4",
    #  "test":      f"{parent_folder}/BurnedTrees-1_setting_5_part2.mp4"},
]

FULLSCREEN = True # False
SIZE = (1280, 720)
BG_COLOR = "black"
TEXT_COLOR = "white"
ISI = 0.25            # gap between videos (s)
RANDOMIZE_ORDER = True  # AB vs BA randomization per trial
RESPONSE_KEYS = ["left", "right", "escape"]  # ←=first video, →=second video
csv_path = f"results/pairwise_{datetime.now().strftime('%Y_%m_%d_%H_%M')}.csv"
OUTPUT_CSV = os.path.join(os.getcwd(), csv_path)
# Encode choice: 1 = test, 0 = reference
# ----------------------------------

def replay_pair(win, first_path, second_path, kb, isi=0.25, noise_dur=0.5):
    # Replay both clips in the same order with the same masks
    play_movie_imageio(win, first_path, kb=kb)
    core.wait(isi)
    show_noise(win, duration=noise_dur, dynamic=True)
    play_movie_imageio(win, second_path, kb=kb)


def message(win, text, wait_key=True, kb=None, height=24):
    msg = visual.TextStim(win, text=text, color=TEXT_COLOR, height=height, wrapWidth=1400)
    msg.draw()
    win.flip()
    if wait_key:
        kb.clearEvents()
        kb.waitKeys()


def show_noise(win, duration=0.5, dynamic=True, std=0.35):
    """
    Grey noise (mean ~0) in PsychoPy's float range [-1,1],
    repeated across RGB so it looks neutral grey.
    std controls contrast (0.25 is moderate; try 0.15 for softer, raise std to be brigher).
    """
    w, h = int(win.size[0]), int(win.size[1])

    def make_noise_frame():
        # grayscale noise in [-1,1] with mean 0
        g = np.random.normal(loc=0.0, scale=std, size=(h, w)).astype(np.float32)
        g = np.clip(g, -1.0, 1.0)
        # tile to RGB so it's grey (no color tint)
        rgb = np.repeat(g[..., None], 3, axis=2)
        return rgb

    frame = make_noise_frame()

    noise_img = visual.ImageStim(
        win,
        image=frame,          # float32 in [-1,1] (grey)
        size=(w, h),
        units="pix",
        interpolate=False,
        opacity=1.0
    )

    t_end = core.getTime() + float(duration)
    if dynamic:
        while core.getTime() < t_end:
            frame[:] = make_noise_frame()
            noise_img.image = frame
            noise_img.draw()
            win.flip()
    else:
        noise_img.draw()
        while core.getTime() < t_end:
            win.flip()


def play_movie_imageio(win, path, kb=None):
    rdr = imageio.get_reader(path, format="ffmpeg")
    try:
        meta = rdr.get_meta_data(); fps = meta.get("fps") or 60
    except Exception:
        fps = 60
    frame_dt = 1.0 / float(fps)

    img_stim = None
    t_next = core.getTime()
    try:
        for frame in rdr:
            if kb and kb.getKeys(['escape'], waitRelease=False):
                break

            # 1) ensure uint8, contiguous, 3 channels
            frame = np.asarray(frame, dtype=np.uint8)
            if frame.ndim == 2:
                frame = np.repeat(frame[:, :, None], 3, axis=2)
            elif frame.shape[2] == 4:
                # keep RGBA or drop alpha—both work; drop if you see warnings:
                frame = frame[:, :, :3]
            frame = np.ascontiguousarray(frame)

            # 2) convert to PIL (PsychoPy handles PIL cleanly as 0..255)
            # pil_img = Image.fromarray(frame, mode="RGB")
            pil_img = Image.fromarray(frame).convert("RGB")            

            if img_stim is None:
                w, h = int(win.size[0]), int(win.size[1])
                img_stim = visual.ImageStim(
                    win,
                    image=pil_img,     # <- PIL image avoids the range check issue
                    size=(w, h),
                    units="pix",
                    interpolate=True, # bilinear filtering in OpenGL
                )
            else:
                img_stim.image = pil_img

            img_stim.draw()
            win.flip()

            t_next += frame_dt
            dt = t_next - core.getTime()
            if dt > 0:
                core.wait(dt)
    finally:
        try: rdr.close()
        except Exception: pass
        win.flip(clearBuffer=True)


def main():
    # win = visual.Window(fullscr=FULLSCREEN, size=SIZE, color=BG_COLOR, units="pix", waitBlanking=False)
    if FULLSCREEN:
        # If fullscreen is True, the 'size' parameter is often ignored or set to the screen resolution by default
        win = visual.Window(fullscr=FULLSCREEN, color=BG_COLOR, units="pix", waitBlanking=False)
    else:
        win = visual.Window(fullscr=FULLSCREEN, size=SIZE, color=BG_COLOR, units="pix", waitBlanking=False)

    kb = keyboard.Keyboard()
    win.mouseVisible = False

    # noise_screen = visual.Rect(win=win, width=win.size[0], height=win.size[1], fillColor=BG_COLOR, autoLog=False)

    # Intro
    message(
        win,
        "Pairwise Video Test\n\n"
        "You will see two videos one after the other.\n"
        "Choose which one looks better.\n\n"
        "Press any key to begin.",
        kb=kb
    )

    # Preload all movies (faster & avoids per-trial open)
    # We’ll keep a cache keyed by path
    movie_cache = {}
    for t in TRIALS:
        for label in ("reference", "test"):
            path = t[label]
            if path not in movie_cache:
                if not os.path.exists(path):
                    win.close(); core.quit()

    # CSV setup
    fieldnames = [
        "trial_index",
        "video_first_label", "video_first_path",
        "video_second_label", "video_second_path",
        "choice", 
    ]
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        # Run trials
        for i, t in enumerate(TRIALS, start=1):
            print(f'\n========== Trial {i} ==========')
            # Determine order (AB or BA)
            order = [("A", "reference"), ("B", "test")]
            if RANDOMIZE_ORDER and random.random() < 0.5:
                order = [("A", "test"), ("B", "reference")]

            # Fixation / ready
            # message(win, f"Trial {i}\n\nPress any key to see the first video.", True, kb=kb)

            # First video
            first_label, first_key = order[0]
            first_path = t[first_key]
            print(f'path1 {first_path}')
            play_movie_imageio(win, first_path, kb=kb)

            core.wait(ISI)
            show_noise(win, duration=0.5, dynamic=True)
            # Second video
            second_label, second_key = order[1]
            second_path = t[second_key]
            print(f'path2 {second_path}\n')
            play_movie_imageio(win, second_path, kb=kb)


            # Prompt for response
            prompt = visual.TextStim(
                win,
                text=("Which video is better?\n\n"
                    "← First    → Second     (Esc to quit)\n"
                    "Backspace = Replay"), 
                color=TEXT_COLOR, height=28
            )
            prompt.draw(); win.flip()
            kb.clearEvents()
            t0 = core.getTime()
            choice = None

            while True:
                keys = kb.getKeys(waitRelease=False)
                if keys:
                    k = keys[-1].name
                    print(f"Key pressed: {k}")  # <-- DEBUG print to see what PsychoPy reads

                    if k in ("escape", "esc"):
                        win.mouseVisible = True
                        win.close()
                        print(f"Results saved to: {OUTPUT_CSV}")
                        core.quit()

                    elif k in ("backspace", "delete", "backspace (8)"):  # handle OS variations
                        print("Replaying both videos...")
                        replay_pair(win, first_path, second_path, kb, isi=ISI, noise_dur=0.5)
                        # Re-show the prompt after replay
                        prompt.draw()
                        win.flip()
                        kb.clearEvents()
                        continue

                    elif k in ("left", "right"):
                        if k == "left":
                            chosen_label = first_key
                        else:
                            chosen_label = second_key
                        choice = 1 if chosen_label == "test" else 0
                        break


            writer.writerow({
                "trial_index": i,
                "video_first_label": first_key,     # which stimulus (reference/test) was first
                "video_first_path": first_path,
                "video_second_label": second_key,   # which was second
                "video_second_path": second_path,
                "choice": choice,                    # 'first' or 'second'
            })
            f.flush()

            # brief inter-trial screen
            message(win, " ", True, kb)

    # Done
    message(win, "All done, thank you!\nPress any key to exit.", True, kb)
    for m in movie_cache.values():
        try:
            m.unload()
        except Exception:
            pass
    win.mouseVisible = True
    win.close()
    print(f"Results saved to: {OUTPUT_CSV}")

if __name__ == "__main__":
    main()
